FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend ./backend
COPY analytics ./analytics
COPY web ./web
ENV HOST=0.0.0.0 PORT=8000
EXPOSE 8000
CMD ["python", "-m", "backend.server"]
