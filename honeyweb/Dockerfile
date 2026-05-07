FROM python:3.11-slim

WORKDIR /app

RUN pip install flask --no-cache-dir

COPY . .

RUN mkdir -p /var/log/honeyweb

EXPOSE 81

CMD ["python", "app.py"]
