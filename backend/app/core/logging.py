import logging
import re
import sys
from contextvars import ContextVar
from typing import Optional

request_id_ctx: ContextVar[Optional[str]] = ContextVar("request_id", default=None)

# Patterns for sensitive tokens, passwords, and API keys
SENSITIVE_PATTERNS = [
    # Bearer token pattern
    (re.compile(r"(Bearer\s+)[A-Za-z0-9\-_.]+", re.IGNORECASE), r"\1[REDACTED_TOKEN]"),
    # Standard 3-part JWT token (eyJ...)
    (re.compile(r"eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]+"), "[REDACTED_JWT]"),
    # Password key-values in JSON / query params
    (re.compile(r'("(?:password|secret|service_role_key|anon_key|token)"\s*:\s*)"[^"]+"', re.IGNORECASE), r'\1"[REDACTED]"'),
    (re.compile(r'((?:password|secret|token)=)[^\s&]+', re.IGNORECASE), r'\1[REDACTED]'),
]


def redact_sensitive_text(text: str) -> str:
    """Mask credentials, tokens, and secrets from a string."""
    if not isinstance(text, str):
        return text
    sanitized = text
    for pattern, replacement in SENSITIVE_PATTERNS:
        sanitized = pattern.sub(replacement, sanitized)
    return sanitized


class RequestIdFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = request_id_ctx.get() or "-"
        return True


class SensitiveDataRedactingFilter(logging.Filter):
    """Filter that intercepts and masks credentials and tokens before log formatting."""
    def filter(self, record: logging.LogRecord) -> bool:
        if isinstance(record.msg, str):
            record.msg = redact_sensitive_text(record.msg)
        if record.args:
            if isinstance(record.args, dict):
                record.args = {
                    k: redact_sensitive_text(v) if isinstance(v, str) else v
                    for k, v in record.args.items()
                }
            elif isinstance(record.args, tuple):
                record.args = tuple(
                    redact_sensitive_text(arg) if isinstance(arg, str) else arg
                    for arg in record.args
                )
        return True


def setup_logging(level: str = "INFO") -> None:
    """Set up structured logging with request context and sensitive data redaction."""
    log_format = (
        "[%(asctime)s] [%(levelname)s] [req:%(request_id)s] "
        "[%(name)s]: %(message)s"
    )
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter(log_format, datefmt="%Y-%m-%dT%H:%M:%SZ"))
    handler.addFilter(RequestIdFilter())
    handler.addFilter(SensitiveDataRedactingFilter())

    root_logger = logging.getLogger()
    root_logger.setLevel(level.upper())
    # Replace existing handlers
    root_logger.handlers = [handler]

    # Suppress overly noisy third-party logs
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)

