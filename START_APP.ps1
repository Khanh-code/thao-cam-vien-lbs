# Chạy app Thảo Cầm Viên: tự tạo .venv, tự cài thư viện còn thiếu, chạy migration rồi mở Streamlit.
# Cách chạy:  powershell -ExecutionPolicy Bypass -File .\START_APP.ps1
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$py = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'

if (-not (Test-Path -LiteralPath $py)) {
    Write-Host '>> Tạo môi trường .venv ...'
    py -m venv .venv
    if ($LASTEXITCODE -ne 0) { python -m venv .venv }
    if (-not (Test-Path -LiteralPath $py)) { throw 'Không tạo được .venv. Hãy cài Python từ python.org (tick "Add python.exe to PATH").' }
}

& $py -c "import streamlit, folium, streamlit_folium, psycopg2, qrcode" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host '>> Cài thư viện (lần đầu mất vài phút) ...'
    & $py -m pip install --upgrade pip
    & $py -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) { throw 'Cài thư viện thất bại, xem thông báo lỗi phía trên.' }
}

Write-Host '>> Chạy migration database ...'
& $py run_migrations.py
if ($LASTEXITCODE -ne 0) { Write-Warning 'Migration lỗi (kiểm tra .streamlit/secrets.toml). App vẫn được mở.' }

Write-Host '>> Mở app tại http://localhost:8501 ...'
& $py -m streamlit run app.py
