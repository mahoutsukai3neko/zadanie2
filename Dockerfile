# Użycie obrazu bazowego
FROM python:3.12.7-slim AS base

# Informacja o autorze
LABEL author="Kateryna Boiko"

# Ustawienie katalogu roboczego na /app
WORKDIR /app

# Instalacja wymaganych bibliotek (requests i pytz)
RUN pip install --no-cache-dir requests pytz 

#Skopiowanie wszystkich plików z bieżącego katalogu
COPY . .

#Ustawienie portu, na którym serwer będzie nasłuchiwał
EXPOSE 8080

# Budowanie obrazu końcowego
FROM base AS final

# Skopiowanie tylko niezbędnych plików do drugiego etapu budowania
COPY main.py .
COPY server_log.txt .

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

# Polecenie uruchamiające serwer
CMD ["python", "main.py"]
