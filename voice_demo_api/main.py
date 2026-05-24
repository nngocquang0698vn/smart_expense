import json
import os
from datetime import datetime
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from dotenv import load_dotenv
from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from openai import AsyncOpenAI, OpenAIError, RateLimitError
from pydantic import BaseModel, Field, ValidationError, field_validator

load_dotenv()

MAX_AUDIO_BYTES = 10 * 1024 * 1024
DEFAULT_LOCALE = "vi-VN"
DEFAULT_TIMEZONE = "Asia/Ho_Chi_Minh"
DEFAULT_TRANSCRIBE_MODEL = "gpt-4o-mini-transcribe"
DEFAULT_PARSE_MODEL = "gpt-4o-mini"

DEFAULT_CATEGORY_OPTIONS = [
    {
        "categoryId": "default_expense_food",
        "categoryKey": "food",
        "categoryName": "Ăn uống",
        "isIncome": False,
        "aliases": ["ăn", "uống", "cafe", "cà phê", "trà sữa", "nhà hàng"],
    },
    {
        "categoryId": "default_expense_shopping",
        "categoryKey": "shopping",
        "categoryName": "Mua sắm",
        "isIncome": False,
        "aliases": ["mua sắm", "shopee", "quần áo", "siêu thị"],
    },
    {
        "categoryId": "default_expense_transport",
        "categoryKey": "transport",
        "categoryName": "Di chuyển",
        "isIncome": False,
        "aliases": ["grab", "taxi", "xe", "xăng", "di chuyển"],
    },
    {
        "categoryId": "default_expense_bills",
        "categoryKey": "bills",
        "categoryName": "Hoá đơn",
        "isIncome": False,
        "aliases": ["hoá đơn", "điện", "nước", "internet", "tiền nhà"],
    },
    {
        "categoryId": "system_khac_expense",
        "categoryKey": "other_expense",
        "categoryName": "Khác",
        "isIncome": False,
        "aliases": ["khác"],
    },
    {
        "categoryId": "default_income_salary",
        "categoryKey": "salary",
        "categoryName": "Lương",
        "isIncome": True,
        "aliases": ["lương", "thu nhập", "tiền công"],
    },
    {
        "categoryId": "system_khac_income",
        "categoryKey": "other_income",
        "categoryName": "Khác",
        "isIncome": True,
        "aliases": ["thu nhập khác", "khác"],
    },
]

ALLOWED_AUDIO_MIME_TYPES = {
    "audio/webm",
    "audio/m4a",
    "audio/x-m4a",
    "audio/mp4",
    "audio/wav",
    "audio/wave",
    "audio/x-wav",
    "audio/mpeg",
    "audio/mp3",
    "audio/ogg",
    "video/webm",
    "video/mp4",
    "application/octet-stream",
}

ALLOWED_AUDIO_EXTENSIONS = {
    ".webm",
    ".m4a",
    ".mp4",
    ".wav",
    ".mpeg",
    ".mpga",
    ".mp3",
    ".ogg",
}


class ApiError(BaseModel):
    code: str
    message: str


class ErrorResponse(BaseModel):
    error: ApiError


class TransactionDraft(BaseModel):
    title: str = Field(default="Giao dịch từ giọng nói")
    amountVnd: int | None = None
    isIncome: bool = False
    categoryName: str | None = None
    categoryKey: str | None = None
    categoryId: str | None = None
    note: str | None = None
    transactionDate: str | None = None
    pending: bool = True
    confidence: float = Field(default=0.0, ge=0.0, le=1.0)

    @field_validator("pending", mode="before")
    @classmethod
    def force_pending(cls, _value: Any) -> bool:
        return True


class VoiceTransactionResponse(BaseModel):
    transcript: str
    transactionDraft: TransactionDraft
    warnings: list[str] = Field(default_factory=list)


def _env(name: str, default: str | None = None) -> str | None:
    value = os.getenv(name)
    if value is None or value.strip() == "":
        return default
    return value.strip()


def _allowed_origins() -> list[str]:
    raw = _env("ALLOWED_ORIGINS")
    if raw:
        return [item.strip() for item in raw.split(",") if item.strip()]
    return [
        "http://localhost:3000",
        "http://localhost:5173",
        "http://localhost:8000",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080",
    ]


def _allowed_origin_regex() -> str | None:
    return _env("ALLOWED_ORIGIN_REGEX")


app = FastAPI(
    title="Smart Expense Voice Demo API",
    version="0.1.0",
    docs_url="/docs",
    redoc_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins(),
    allow_origin_regex=_allowed_origin_regex(),
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "X-Demo-Token"],
)


def _json_error(status_code: int, code: str, message: str) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail=ErrorResponse(error=ApiError(code=code, message=message)).model_dump(),
    )


@app.exception_handler(HTTPException)
async def _http_exception_handler(_request, exc: HTTPException):
    from fastapi.responses import JSONResponse

    if isinstance(exc.detail, dict) and "error" in exc.detail:
        return JSONResponse(status_code=exc.status_code, content=exc.detail)
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": "http_error",
                "message": str(exc.detail),
            },
        },
    )


@app.exception_handler(Exception)
async def _unexpected_exception_handler(_request, exc: Exception):
    from fastapi.responses import JSONResponse

    return JSONResponse(
        status_code=500,
        content={
            "error": {
                "code": "internal_error",
                "message": f"Lỗi backend chưa xử lý: {exc.__class__.__name__}.",
            },
        },
    )


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/voice-transaction-demo", response_model=VoiceTransactionResponse)
async def voice_transaction_demo(
    audio: UploadFile = File(...),
    locale: str = Form(DEFAULT_LOCALE),
    timezone: str = Form(DEFAULT_TIMEZONE),
    x_demo_token: str | None = Header(default=None, alias="X-Demo-Token"),
) -> VoiceTransactionResponse:
    _check_demo_token(x_demo_token)
    _require_openai_key()

    audio_bytes = await audio.read()
    _validate_audio(audio, audio_bytes)

    transcript = await _transcribe_audio(
        audio_bytes=audio_bytes,
        filename=audio.filename or "voice_note.m4a",
        content_type=audio.content_type or "application/octet-stream",
        locale=locale,
    )
    if transcript.strip() == "":
        fallback = _fallback_response(
            transcript="",
            timezone=timezone,
            warnings=["transcript_empty", "parse_failed", "amount_missing"],
        )
        return fallback

    return await _parse_transcript(
        transcript=transcript,
        locale=locale,
        timezone=timezone,
    )


def _check_demo_token(header_token: str | None) -> None:
    expected = _env("DEMO_TOKEN")
    if expected is None:
        return
    if header_token != expected:
        raise _json_error(
            401,
            "unauthorized",
            "Demo token không hợp lệ hoặc bị thiếu.",
        )


def _require_openai_key() -> None:
    if _env("OPENAI_API_KEY") is None:
        raise _json_error(
            500,
            "openai_key_missing",
            "Backend chưa được cấu hình OPENAI_API_KEY.",
        )


def _openai_error_message(exc: OpenAIError) -> str:
    status_code = getattr(exc, "status_code", None)
    request_id = getattr(exc, "request_id", None)
    error_code = getattr(exc, "code", None)
    body = getattr(exc, "body", None)
    if isinstance(body, dict):
        error = body.get("error")
        if isinstance(error, dict):
            error_code = error_code or error.get("code") or error.get("type")

    details = [exc.__class__.__name__]
    if status_code is not None:
        details.append(f"status={status_code}")
    if error_code:
        details.append(f"code={error_code}")
    if request_id:
        details.append(f"request_id={request_id}")
    return ", ".join(details)


def _validate_audio(upload: UploadFile, data: bytes) -> None:
    if not data:
        raise _json_error(400, "audio_empty", "File audio đang trống.")
    if len(data) > MAX_AUDIO_BYTES:
        raise _json_error(
            413,
            "audio_too_large",
            "File audio vượt quá giới hạn 10MB cho demo.",
        )

    filename = upload.filename or ""
    extension = Path(filename).suffix.lower()
    content_type = (upload.content_type or "").split(";")[0].lower()
    mime_ok = content_type in ALLOWED_AUDIO_MIME_TYPES
    extension_ok = extension in ALLOWED_AUDIO_EXTENSIONS
    if not mime_ok and not extension_ok:
        raise _json_error(
            400,
            "audio_type_unsupported",
            "Chỉ hỗ trợ audio webm, m4a/mp4, wav, mp3/mpeg hoặc ogg.",
        )

async def _transcribe_audio(
    *,
    audio_bytes: bytes,
    filename: str,
    content_type: str,
    locale: str,
) -> str:
    client = AsyncOpenAI(api_key=_env("OPENAI_API_KEY"))
    model = _env("OPENAI_TRANSCRIBE_MODEL", DEFAULT_TRANSCRIBE_MODEL)
    prompt = (
        "Nhận diện chính xác ghi chú tài chính cá nhân bằng tiếng Việt. "
        "Giữ tiếng Việt có dấu khi âm thanh đủ rõ. "
        f"Locale hint: {locale}."
    )
    try:
        result = await client.audio.transcriptions.create(
            model=model,
            file=(filename, audio_bytes, content_type),
            response_format="json",
            prompt=prompt,
        )
    except RateLimitError as exc:
        raise _json_error(
            429,
            "openai_rate_limited",
            (
                "OpenAI API đang báo hết quota hoặc bị giới hạn tốc độ. "
                "Hãy kiểm tra Billing, Usage/Limits, đúng Project/API key, "
                f"rồi thử lại sau vài phút. Model: {model}. "
                f"Chi tiết: {_openai_error_message(exc)}."
            ),
        ) from exc
    except OpenAIError as exc:
        raise _json_error(
            502,
            "transcription_failed",
            (
                "Không thể nhận diện giọng nói từ audio. "
                f"Model: {model}. Chi tiết OpenAI: {_openai_error_message(exc)}."
            ),
        ) from exc

    text = getattr(result, "text", None)
    if isinstance(text, str):
        return text.strip()
    if isinstance(result, dict) and isinstance(result.get("text"), str):
        return result["text"].strip()
    return str(result).strip()


async def _parse_transcript(
    *,
    transcript: str,
    locale: str,
    timezone: str,
) -> VoiceTransactionResponse:
    now = _now_iso(timezone)
    client = AsyncOpenAI(api_key=_env("OPENAI_API_KEY"))
    model = _env("OPENAI_PARSE_MODEL", DEFAULT_PARSE_MODEL)
    system_prompt = _parse_system_prompt()
    user_payload = {
        "transcript": transcript,
        "locale": locale,
        "timezone": timezone,
        "now": now,
    }

    try:
        completion = await client.chat.completions.create(
            model=model,
            temperature=0,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": system_prompt},
                {
                    "role": "user",
                    "content": json.dumps(user_payload, ensure_ascii=False),
                },
            ],
        )
        content = completion.choices[0].message.content or "{}"
        raw = json.loads(content)
        response = _coerce_parse_result(raw, transcript)
    except (OpenAIError, json.JSONDecodeError, ValidationError, KeyError, IndexError) as exc:
        return _fallback_response(
            transcript=transcript,
            timezone=timezone,
            warnings=["parse_failed", "amount_missing", exc.__class__.__name__],
        )

    warnings = _normalize_warnings(response.warnings)
    draft = _normalize_category(
        response.transactionDraft.model_copy(
            update={
                "pending": True,
                "note": response.transactionDraft.note or transcript,
            },
        ),
    )
    if draft.amountVnd is None:
        warnings.append("amount_missing")
    if draft.categoryId is None:
        warnings.append("category_unresolved")
    if draft.transactionDate is None:
        warnings.append("date_uncertain")

    return VoiceTransactionResponse(
        transcript=response.transcript or transcript,
        transactionDraft=draft,
        warnings=_normalize_warnings(warnings),
    )


def _parse_system_prompt() -> str:
    template = """
You parse Vietnamese speech transcripts into a Smart Expense transaction draft.
Return JSON only with this exact shape:
{
  "transcript": string,
  "transactionDraft": {
    "title": string,
    "amountVnd": integer|null,
    "isIncome": boolean,
    "categoryName": string|null,
    "categoryKey": string|null,
    "categoryId": string|null,
    "note": string|null,
    "transactionDate": ISO-8601 string|null,
    "pending": true,
    "confidence": number between 0 and 1
  },
  "warnings": string[]
}

Rules:
- Prioritize Vietnamese.
- Never invent missing information.
- Always set pending=true.
- Default isIncome=false unless transcript clearly describes income.
- Prefer natural Vietnamese with accents for title, categoryName, and note.
- Understand Vietnamese money phrases such as "35 nghìn", "35k",
  "một trăm hai mươi nghìn".
- Resolve relative dates using the supplied timezone and now:
  "hôm nay", "hôm qua", "sáng nay", "tối qua".
- If amount is unclear, set amountVnd=null and include "amount_missing".
- Choose categoryKey/categoryId/categoryName only from this default category list:
{categories}
- If category is uncertain, choose "other_expense" for expenses or "other_income"
  for income and include "category_unresolved".
- If date is ambiguous, set transactionDate=null and include "date_uncertain".
""".strip()
    return template.replace(
        "{categories}",
        json.dumps(DEFAULT_CATEGORY_OPTIONS, ensure_ascii=False),
    )


def _coerce_parse_result(raw: dict[str, Any], transcript: str) -> VoiceTransactionResponse:
    if "transactionDraft" not in raw:
        raw = {
            "transcript": raw.get("transcript", transcript),
            "transactionDraft": raw,
            "warnings": raw.get("warnings", []),
        }
    raw["transcript"] = raw.get("transcript") or transcript
    raw["warnings"] = raw.get("warnings") or []
    draft = raw["transactionDraft"] or {}
    draft["pending"] = True
    if not draft.get("title"):
        draft["title"] = _short_title(transcript)
    if not draft.get("note"):
        draft["note"] = transcript
    raw["transactionDraft"] = draft
    return VoiceTransactionResponse.model_validate(raw)


def _fallback_response(
    *,
    transcript: str,
    timezone: str,
    warnings: list[str],
) -> VoiceTransactionResponse:
    return VoiceTransactionResponse(
        transcript=transcript,
        transactionDraft=TransactionDraft(
            title=_short_title(transcript),
            amountVnd=None,
            isIncome=False,
            categoryName="Khác",
            categoryKey="other_expense",
            categoryId="system_khac_expense",
            note=transcript or None,
            transactionDate=None,
            pending=True,
            confidence=0.2 if transcript else 0.0,
        ),
        warnings=_normalize_warnings(warnings + ["category_unresolved"]),
    )


def _short_title(transcript: str) -> str:
    cleaned = " ".join(transcript.strip().split())
    if cleaned == "":
        return "Giao dịch từ giọng nói"
    return cleaned[:60]


def _normalize_category(draft: TransactionDraft) -> TransactionDraft:
    option = _find_category_option(draft)
    if option is None:
        option = _other_option(draft.isIncome)
    return draft.model_copy(
        update={
            "categoryId": option["categoryId"],
            "categoryKey": option["categoryKey"],
            "categoryName": option["categoryName"],
            "isIncome": option["isIncome"],
        },
    )


def _find_category_option(draft: TransactionDraft) -> dict[str, Any] | None:
    for option in DEFAULT_CATEGORY_OPTIONS:
        if draft.categoryId == option["categoryId"]:
            return option
        if draft.categoryKey == option["categoryKey"]:
            return option
    wanted_name = _normalize_text(draft.categoryName or "")
    if wanted_name:
        for option in DEFAULT_CATEGORY_OPTIONS:
            if wanted_name == _normalize_text(option["categoryName"]):
                return option
    return None


def _other_option(is_income: bool) -> dict[str, Any]:
    key = "other_income" if is_income else "other_expense"
    return next(option for option in DEFAULT_CATEGORY_OPTIONS if option["categoryKey"] == key)


def _normalize_text(value: str) -> str:
    return " ".join(value.strip().lower().split())


def _now_iso(timezone: str) -> str:
    try:
        tz = ZoneInfo(timezone)
    except ZoneInfoNotFoundError:
        try:
            tz = ZoneInfo(DEFAULT_TIMEZONE)
        except ZoneInfoNotFoundError:
            return datetime.now().astimezone().isoformat()
    return datetime.now(tz).isoformat()


def _normalize_warnings(warnings: list[str]) -> list[str]:
    result: list[str] = []
    for warning in warnings:
        item = str(warning).strip()
        if item and item not in result:
            result.append(item)
    return result
