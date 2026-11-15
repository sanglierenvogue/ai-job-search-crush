#!/usr/bin/env python3
"""Analyze rendered CV page images with a vision-capable LLM.

Sends rendered CV pages (PNG/JPEG/WebP/GIF) to an OpenAI-compatible
chat-completions gateway as base64 data URLs in the standard OpenAI
`image_url` content parts, and prints the model's analysis.

Usage:
    .scripts/analyze-cv-vision.py [image.png ...] [options]

With no images the script runs in text-only mode (plain string content),
which is useful to verify credentials and model id before spending on
image tokens.

Configuration (process environment wins over repo-root .env):
    LLM_API_KEY    required; bearer key for the gateway
    LLM_BASE_URL   optional; gateway base URL (default: the OpenAI
                   default endpoint; point this at your own gateway)
    LLM_MODEL      optional; model id (default: qwen3.8-27b)

Exit codes (repo convention): 64 bad usage, 66 missing input,
69 missing key, 75 HTTP/network failure.
"""

import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

DEFAULT_BASE_URL = "https://api.openai.com/v1"
DEFAULT_MODEL = "qwen3.8-27b"

MIME_BY_SUFFIX = {
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".webp": "image/webp",
    ".gif": "image/gif",
}

DEFAULT_PROMPT = """\
You are reviewing a rendered CV page (page {page} of {total}). Report \
precisely, without inventing anything:
1. Candidate name and all position titles in the header
2. Every contact detail shown (address, phone, email, LinkedIn, GitHub)
3. The section headings in the order they appear
4. For each entry: title, organization, location, and date
5. Any rendering problems: clipped or overlapping text, missing glyphs \
or icons, an entry or section heading left alone at the bottom of the \
page, or inconsistent spacing
If a requested item is not present on this page, say so explicitly."""


def die(code, message):
    print(f"error: {message}", file=sys.stderr)
    sys.exit(code)


def load_dotenv():
    """Load KEY=VALUE lines from repo-root .env (process env wins)."""
    env_file = ROOT / ".env"
    if not env_file.is_file():
        return
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key:
            os.environ.setdefault(key, value)


def redact(text, key):
    if key and len(key) >= 8 and key in text:
        return text.replace(key, "***redacted***")
    return text


def build_content(images, prompt, detail):
    if not images:
        return prompt
    parts = [{"type": "text", "text": prompt}]
    for path in images:
        mime = MIME_BY_SUFFIX[path.suffix.lower()]
        encoded = base64.b64encode(path.read_bytes()).decode("ascii")
        parts.append({
            "type": "image_url",
            "image_url": {
                "url": f"data:{mime};base64,{encoded}",
                "detail": detail,
            },
        })
    return parts


def call_gateway(base_url, key, model, content, max_tokens,
                 reasoning_effort, timeout):
    body = {
        "model": model,
        "messages": [{"role": "user", "content": content}],
        "max_tokens": max_tokens,
    }
    if reasoning_effort:
        body["reasoning_effort"] = reasoning_effort
    request = urllib.request.Request(
        f"{base_url.rstrip('/')}/chat/completions",
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            try:
                return json.loads(response.read().decode("utf-8"))
            except ValueError as exc:
                die(75, f"invalid JSON in response: {exc}")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        die(75, f"HTTP {exc.code} from {exc.url}: {redact(detail, key)}")
    except urllib.error.URLError as exc:
        die(75, f"network error: {exc.reason}")
    except TimeoutError:
        die(75, f"timed out after {timeout}s")


def parse_args(argv):
    class _Parser(argparse.ArgumentParser):
        def error(self, message):
            self.print_usage(sys.stderr)
            die(64, message)

    parser = _Parser(
        description="Analyze rendered CV pages with a vision-capable LLM "
                    "(OpenAI-compatible chat-completions gateway).")
    parser.add_argument(
        "images", nargs="*", type=Path,
        help="rendered CV page images (PNG/JPEG/WebP/GIF); omit all for a "
             "text-only smoke test")
    parser.add_argument("--prompt", help="prompt text (default: CV analysis)")
    parser.add_argument("--model", help=f"model id (default: $LLM_MODEL or "
                                        f"{DEFAULT_MODEL})")
    parser.add_argument("--base-url", help="gateway base URL (default: "
                                           f"$LLM_BASE_URL or {DEFAULT_BASE_URL})")
    parser.add_argument("--detail", choices=("auto", "low", "high"),
                        default="high", help="image detail level (default: high)")
    parser.add_argument("--max-tokens", type=int, default=2048,
                        help="max completion tokens (default: 2048)")
    parser.add_argument("--reasoning-effort", default="none",
                        help="reasoning effort; 'none' keeps thinking off "
                             "(default: none); pass an empty string to "
                             "omit the field")
    parser.add_argument("--timeout", type=int, default=120,
                        help="request timeout in seconds (default: 120)")
    parser.add_argument("--save", type=Path,
                        help="also write the result to this file")
    parser.add_argument("--json", action="store_true",
                        help="print the raw response JSON instead of just "
                             "the assistant text")
    args = parser.parse_args(argv)
    for path in args.images:
        if not path.is_file():
            die(66, f"no such file: {path}")
        if path.suffix.lower() not in MIME_BY_SUFFIX:
            die(64, f"unsupported image type: {path.suffix} "
                    f"(supported: {', '.join(sorted(MIME_BY_SUFFIX))})")
    return args


def main(argv=None):
    args = parse_args(argv)
    load_dotenv()

    key = os.environ.get("LLM_API_KEY", "").strip()
    if not key:
        die(69, "LLM_API_KEY not set (put it in the repo-root .env; see "
                ".env.example)")
    base_url = (args.base_url or os.environ.get("LLM_BASE_URL", "").strip()
                or DEFAULT_BASE_URL)
    model = (args.model or os.environ.get("LLM_MODEL", "").strip()
             or DEFAULT_MODEL)

    if args.images:
        prompt = (args.prompt or DEFAULT_PROMPT).format(
            page="each of", total=len(args.images))
    else:
        prompt = args.prompt or "Reply with the single word: ok"
    content = build_content(args.images, prompt, args.detail)

    response = call_gateway(base_url, key, model, content, args.max_tokens,
                            args.reasoning_effort, args.timeout)

    if args.json:
        output = json.dumps(response, indent=2)
    else:
        try:
            output = response["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError):
            die(75, f"unexpected response shape: {redact(json.dumps(response)[:500], key)}")
        usage = response.get("usage")
        if usage:
            output = (f"{output}\n\n"
                      f"(tokens: {usage.get('prompt_tokens', '?')} in, "
                      f"{usage.get('completion_tokens', '?')} out)")

    print(output)
    if args.save:
        args.save.write_text(output + "\n", encoding="utf-8")
        print(f"saved: {args.save}", file=sys.stderr)


if __name__ == "__main__":
    main()
