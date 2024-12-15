#Program serwera
import socket  
import datetime  
import pytz  
import requests  

HOST = '0.0.0.0'  #Serwer nasłuchuje na wszystkich dostępnych interfejsach sieciowych  
PORT = 8080  #Port, na którym serwer będzie nasłuchiwał  

def log_server_start():  
    #Funkcja logująca uruchomienie serwera  
    start_time = datetime.datetime.now()  #Pobranie aktualnej daty i godziny  
    author_name = "Kateryna Boiko"  #Tutaj wpisz swoje imię i nazwisko  
    log_message = f"Server started at {start_time} by {author_name} on port {PORT}"  
    with open("server_log.txt", "a") as log_file:  
        log_file.write(log_message + "\n")  #Zapisanie informacji do pliku loga  
    print(log_message)  

    print("\nContents of server_log.txt:")  
    with open("server_log.txt", "r") as log_file: #Otwarcie pliku `server_log.txt` w trybie do odczytu.  
        print(log_file.read())  

def get_client_time(client_ip):  
    #Funkcja pobierająca aktualny czas w strefie czasowej klienta na podstawie jego adresu IP  
    try:  
      #Korzystanie z ip-api.com do geolokalizacji  
        response = requests.get(f"http://ip-api.com/json/{client_ip}")  
        data = response.json()  

        if data["status"] == "success":  
            timezone = data.get("timezone", "UTC")  #Pobieranie strefy czasowej  
            tz = pytz.timezone(timezone)  
        else:  
            tz = pytz.utc  #Domyślnie UTC  
    except Exception as e:  
        print(f"Failed to determine timezone for {client_ip}: {e}")  
        tz = pytz.utc  
    return datetime.datetime.now(tz)  #Zwracamy aktualny czas w strefie czasowej klienta  

def generate_html(client_ip, client_time):  
    #Funkcja generująca stronę HTML z informacjami o kliencie   
    html_content = f"""  
    <html>  
    <head>  
        <title>Informacje o kliencie</title>  
    </head>  
    <body>  
        <h1>Adres IP klienta: {client_ip}</h1>  
        <p>Czas klienta: {client_time}</p>  
    </body>    
    </html>  
    """  
    return html_content  #Zwracamy wygenerowaną stronę HTML  

def run_server():  
    log_server_start()  #Logujemy uruchomienie serwera  
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:  
        server_socket.bind((HOST, PORT))  #Wiążemy gniazdo z adresem i portem  
        server_socket.listen()  #Serwer zaczyna nasłuchiwać na połączenia  
        print(f"Server is listening on {HOST}:{PORT}")  
        
        while True:  
            client_socket, client_address = server_socket.accept()  #Akceptujemy nowe połączenie  
            with client_socket:  
                print(f"Connected by {client_address}")  #Informacja o nowym połączeniu  
                client_ip = client_address[0]  #Pobieramy adres IP klienta  
                client_time = get_client_time(client_ip)  #Pobieramy czas w strefie czasowej klienta  
                response = generate_html(client_ip, client_time)  #Generujemy stronę HTML z informacjami o kliencie  
                client_socket.sendall(f"HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n{response}".encode())  #Wysyłamy stronę HTML do przeglądarki klienta  

if __name__ == "__main__":  
    run_server()  #Uruchamiamy serwer  

#Zawartość pliku Dockerfile  

#Użycie obrazu bazowego  
FROM python:3.12.7-slim AS base  

#Informacja o autorze  
LABEL author="Kateryna Boiko"  

#Ustawienie katalogu roboczego na /app  
WORKDIR /app  

#Instalacja wymaganych bibliotek (requests i pytz)  
RUN pip install --no-cache-dir requests pytz   

#Skopiowanie wszystkich plików z bieżącego katalogu  
COPY . .  

#Ustawienie portu, na którym serwer będzie nasłuchiwał  
EXPOSE 8080  

#Budowanie obrazu końcowego    
FROM base AS final  

#Skopiowanie tylko niezbędnych plików do drugiego etapu budowania  
COPY main.py .  
COPY server_log.txt .  

#Healthcheck  
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \  
  CMD curl -f http://localhost:8080/ || exit 1  

#Polecenie uruchamiające serwer  
CMD ["python", "main.py"]  


Polecenia niezbędne do:   
a. zbudowania opracowanego obrazu kontenera  

docker build -t docker.io/iol4/lab:server .  
docker push docker.io/iol4/lab:server  

b. uruchomienia kontenera na podstawie zbudowanego obrazu  

docker run -p 8080:8080 --name server_container docker.io/iol4/lab:server  

c. sposobu uzyskania informacji, które wygenerował serwer w trakcie uruchamiana kontenera   

docker logs server_container  

d. sprawdzenia, ile warstw posiada zbudowany obraz  

docker history docker.io/iol4/lab:server  
