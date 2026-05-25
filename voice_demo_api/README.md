# Smart Expense Voice Demo API

FastAPI backend demo for Smart Expense AI Voice Transaction.

The Flutter app uploads a short audio file. This service transcribes it with OpenAI speech-to-text, then asks a text model to parse the transcript into a transaction draft. The returned draft is always `pending: true` so the app can keep the current review flow.

This is demo-level infrastructure for a school presentation, not production auth/rate-limit/storage.

## Contract

### `GET /health`

Returns:

```json
{ "status": "ok" }
```

### `POST /voice-transaction-demo`

Request:

- `multipart/form-data`
- `audio`: required file
- `locale`: optional, default `vi-VN`
- `timezone`: optional, default `Asia/Ho_Chi_Minh`
- Header `X-Demo-Token`: optional unless `DEMO_TOKEN` is set

Success response:

```json
{
  "transcript": "ăn tối 85000 hôm nay",
  "transactionDraft": {
    "title": "Ăn tối",
    "amountVnd": 85000,
    "isIncome": false,
    "categoryName": "Ăn uống",
    "categoryKey": "food",
    "categoryId": "default_expense_food",
    "note": "ăn tối 85000 hôm nay",
    "transactionDate": "2026-05-24T19:30:00+07:00",
    "pending": true,
    "confidence": 0.82
  },
  "warnings": []
}
```

Error response:

```json
{
  "error": {
    "code": "string",
    "message": "string"
  }
}
```

## Local Development

Use Python 3.12 for this demo backend. The backend folder includes `.python-version` so local `uv` and Render can use the same major/minor Python line.

Install `uv` on Windows PowerShell:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Close and reopen PowerShell if `uv` is not recognized after installation, then check:

```powershell
uv --version
```

Create the environment and install dependencies:

```powershell
cd voice_demo_api
uv python install 3.12
uv venv --python 3.12
uv pip install -r requirements.txt
copy .env.example .env
```

After any `requirements.txt` change, run this again inside `voice_demo_api`:

```powershell
uv pip install -r requirements.txt
```

On Windows this installs `tzdata` too, which lets Python resolve `Asia/Ho_Chi_Minh` correctly.

Edit `.env` and set:

```env
OPENAI_API_KEY=sk-...
```

Run:

```powershell
uv run uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Health check:

```powershell
curl.exe http://127.0.0.1:8000/health
```

## OpenAI API Billing Setup

ChatGPT Plus and OpenAI API billing are separate. A ChatGPT Plus subscription does not automatically give API quota for this backend.

Do this once before testing `/voice-transaction-demo`:

1. Open the OpenAI Platform:

```text
https://platform.openai.com/
```

2. Check the active organization/project:

- Look at the organization/project switcher in the top-left area.
- Pick the organization/project you want this demo API to use.
- If you have more than one organization, make sure you are not adding billing to one org but creating the API key in another org.

3. Add API billing:

```text
https://platform.openai.com/settings/organization/billing/overview
```

- Click **Add payment details** if no payment method exists.
- If prepaid credits are required for your account, buy a small amount of credits for demo usage.
- If auto recharge appears and you do not want automatic top-up, turn it off before confirming.

4. Check usage limits:

```text
https://platform.openai.com/settings/organization/limits
```

- Confirm the organization has a usable monthly/API limit.
- Make sure the models used by this backend are allowed:
  - `OPENAI_TRANSCRIBE_MODEL`, default `gpt-4o-mini-transcribe`
  - `OPENAI_PARSE_MODEL`, default `gpt-4o-mini`

5. Create a fresh API key in the same project:

```text
https://platform.openai.com/api-keys
```

- Click **Create new secret key**.
- Choose the same project that has billing/limits enabled.
- Copy the key once. Do not commit it to git.

6. Update local `.env`:

```env
OPENAI_API_KEY=sk-your-new-key
# DEMO_TOKEN=optional-demo-token
```

7. Restart the backend after changing `.env`:

```powershell
uv run uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

8. Convert `samples/01.aac` to `samples/01.m4a`, then test again.

If you still get:

```json
{
  "error": {
    "code": "openai_rate_limited"
  }
}
```

Check these likely causes:

- Billing was just added and has not propagated yet. Wait a few minutes and retry.
- The API key belongs to a project without billing or without model access.
- You added billing to a different organization than the one used by the API key.
- Usage/limits are still zero or the model is not enabled for the project.
- The account needs prepaid credits, not just a saved card.

If billing and credits are already active, create a new key in the Default project and retry:

```powershell
# Update .env first:
# OPENAI_API_KEY=sk-your-new-default-project-key

uv run uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Then run the curl upload again and read the JSON error body. The backend returns safe OpenAI debug details such as:

```json
{
  "error": {
    "code": "transcription_failed",
    "message": "Không thể nhận diện giọng nói từ audio. Model: gpt-4o-mini-transcribe. Chi tiết OpenAI: NotFoundError, status=404, code=model_not_found."
  }
}
```

Useful meanings:

- `openai_rate_limited`, `status=429`, or `insufficient_quota`: billing/credits/limits are still not active for the key's project.
- `AuthenticationError` or `status=401`: API key is missing, invalid, revoked, or copied incorrectly.
- `PermissionDeniedError` or `status=403`: the key/project does not have access to the requested model.
- `NotFoundError`, `status=404`, or `model_not_found`: change the model env value or enable the model for the project.

For a conservative transcription fallback, try this in `.env`:

```env
OPENAI_TRANSCRIBE_MODEL=whisper-1
OPENAI_PARSE_MODEL=gpt-4o-mini
```

Restart the server after every `.env` change.

### Convert and Test `samples/01.aac`

Place your sample audio inside the backend folder, next to `main.py`:

```text
smart_expense/
  voice_demo_api/
    main.py
    converter.py
    samples/
      01.aac
```

From `voice_demo_api`, confirm the file exists:

```powershell
cd voice_demo_api
Test-Path .\samples\01.aac
```

Convert raw AAC to an M4A container supported by OpenAI transcription:

```powershell
uv run python converter.py samples/01.aac samples/01.m4a
Test-Path .\samples\01.m4a
```

Start the API from `voice_demo_api`:

```powershell
uv run uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Open another terminal in `voice_demo_api` and upload `samples/01.m4a`:

```powershell
curl.exe -X POST "http://127.0.0.1:8000/voice-transaction-demo" `
  -F "audio=@samples/01.m4a;type=audio/m4a" `
  -F "locale=vi-VN" `
  -F "timezone=Asia/Ho_Chi_Minh"
```

If `DEMO_TOKEN` is set in `.env`:

```powershell
curl.exe -X POST "http://127.0.0.1:8000/voice-transaction-demo" `
  -H "X-Demo-Token: your-demo-token" `
  -F "audio=@samples/01.m4a;type=audio/m4a" `
  -F "locale=vi-VN" `
  -F "timezone=Asia/Ho_Chi_Minh"
```

Expected response shape:

```json
{
  "transcript": "ăn sáng 35 nghìn hôm nay",
  "transactionDraft": {
    "title": "Ăn sáng",
    "amountVnd": 35000,
    "isIncome": false,
    "categoryName": "Ăn uống",
    "categoryKey": "food",
    "categoryId": "default_expense_food",
    "note": "ăn sáng 35 nghìn hôm nay",
    "transactionDate": "2026-05-24T08:00:00+07:00",
    "pending": true,
    "confidence": 0.8
  },
  "warnings": []
}
```

`transactionDate`, `confidence`, and `warnings` can vary depending on audio clarity and transcript content.

`converter.py` keeps the backend request path simple. It remuxes raw AAC into an M4A container first, and only re-encodes if ffmpeg cannot copy the audio stream cleanly.

Actual local test output from `samples/01.m4a`:

```powershell
PS C:\Users\nngocquang\Documents\e\smart-ledger-ui-ux\smart_expense\voice_demo_api> curl.exe -X POST "http://127.0.0.1:8000/voice-transaction-demo" `
>>   -F "audio=@samples/01.m4a;type=audio/m4a" `
>>   -F "locale=vi-VN" `
>>   -F "timezone=Asia/Ho_Chi_Minh"
{"transcript":"Nạp kênh điện thoại hết 100.000.","transactionDraft":{"title":"Nạp kênh điện thoại","amountVnd":100000,"isIncome":false,"categoryName":"Khác","categoryKey":"other_expense","categoryId":"system_khac_expense","note":"Nạp kênh điện thoại hết 100.000.","transactionDate":null,"pending":true,"confidence":1.0},"warnings":["date_uncertain"]}
PS C:\Users\nngocquang\Documents\e\smart-ledger-ui-ux\smart_expense\voice_demo_api>
```

If the API returns `openai_rate_limited`, follow the **OpenAI API Billing Setup** checklist above.

Upload test using the Flutter seed audio if the file exists:

```powershell
curl.exe -X POST "http://127.0.0.1:8000/voice-transaction-demo" `
  -F "audio=@../assets/seed/audio/voice_note.mp3" `
  -F "locale=vi-VN" `
  -F "timezone=Asia/Ho_Chi_Minh"
```

## Render Deployment

This repo can host the Flutter app and the demo API together. Render should only build the backend folder.

1. Push this repository to GitHub.
2. Open Render Dashboard.
3. Choose **New +** -> **Web Service**.
4. Connect the GitHub repository.
5. Configure the service:

- Service type: Web Service
- Runtime: Python
- Root Directory: `voice_demo_api`
- Build Command: `pip install uv && uv pip install --system -r requirements.txt`
- Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

The backend folder also has `.python-version` set to `3.12`. If Render does not pick it up, set `PYTHON_VERSION=3.12` in Environment Variables.

6. Set environment variables on Render:

- `OPENAI_API_KEY`: required
- `DEMO_TOKEN`: optional
- `ALLOWED_ORIGINS`: comma-separated exact origins for local and production web
- `ALLOWED_ORIGIN_REGEX`: optional regex for dynamic preview deploy origins
- `PYTHON_VERSION`: optional fallback, use `3.12` if needed
- `OPENAI_TRANSCRIBE_MODEL`: optional, default `gpt-4o-mini-transcribe`
- `OPENAI_PARSE_MODEL`: optional, default `gpt-4o-mini`

Recommended Render CORS values for this demo:

```text
ALLOWED_ORIGINS=https://smart-expense.pages.dev,http://localhost:8080,http://127.0.0.1:8080,http://localhost:5173,http://127.0.0.1:5173
ALLOWED_ORIGIN_REGEX=https://.*\.smart-expense\.pages\.dev
```

`ALLOWED_ORIGINS` is for exact origins. Use it for local dev and the main Cloudflare Pages domain.

`ALLOWED_ORIGIN_REGEX` lets temporary Cloudflare Pages preview URLs call the API too, for example:

```text
https://ba306eb1.smart-expense.pages.dev
```

Do not include a trailing slash in origins.

7. Click **Create Web Service** and wait for the deploy to finish.
8. Open the Render URL and test:

```powershell
curl.exe https://smart-expense-m8nm.onrender.com/health
```

9. Test upload after setting `OPENAI_API_KEY`:

```powershell
curl.exe -X POST "https://smart-expense-m8nm.onrender.com/voice-transaction-demo" `
  -F "audio=@samples/01.m4a;type=audio/m4a" `
  -F "locale=vi-VN" `
  -F "timezone=Asia/Ho_Chi_Minh"
```

If `DEMO_TOKEN` is set:

```powershell
curl.exe -X POST "https://smart-expense-m8nm.onrender.com/voice-transaction-demo" `
  -H "X-Demo-Token: your-demo-token" `
  -F "audio=@samples/01.m4a;type=audio/m4a" `
  -F "locale=vi-VN" `
  -F "timezone=Asia/Ho_Chi_Minh"
```

Replace `your-demo-token` with the exact `DEMO_TOKEN` value configured in Render Environment Variables.

Do not commit `.env` or real secrets.

## Flutter Configuration

After Render deploys, copy the service URL and pass it to Flutter later with a dart define, for example:

```powershell
flutter run -d chrome --dart-define=VOICE_TRANSACTION_API_BASE_URL=https://your-service.onrender.com
```

If you enable `DEMO_TOKEN`, treat any Flutter-side token as a demo gate only, not a real secret.

## Demo Notes

- Render free instances may sleep. Open `/health` before presenting.
- The API rejects files over 10MB.
- Accepted upload types/extensions include WebM, M4A/MP4, WAV, MP3/MPEG, and OGG. For raw `.aac` samples, run `converter.py` and upload the generated `.m4a`.
- Uploaded audio is read in memory for the request and is not stored.
- The API returns a default `categoryKey`, `categoryId`, and `categoryName`.
- For no-extra-processing Flutter usage, the Flutter default category seed uses the same stable IDs:
  - `default_expense_food` -> `Ăn uống`
  - `default_expense_shopping` -> `Mua sắm`
  - `default_expense_transport` -> `Di chuyển`
  - `default_expense_bills` -> `Hoá đơn`
  - `system_khac_expense` -> `Khác`
  - `default_income_salary` -> `Lương`
  - `system_khac_income` -> `Khác`
- `pending` is forced to `true` on the backend even if the model returns something else.
