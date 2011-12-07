Chgspam
=======

Bartosz Pranczke
----------------

### Opis ###
Chgspam jest to pakiet zawierający serwer oraz klient mający na celu gromadzenie
adresów e-mail poprzez odwiedzanie stron internetowych. Klient oprócz zbierania 
adresów e-mail gromadzi także kolejny domeny do sprawdzenia.

### Architektura ###
<pre>
                             +-----------+
                             |  Klient   |
                             +-----------+
                                 ^ +
                                 | |
                                 + v
       +------------+ &lt;----+ +-----------+ +----&gt; +-----------+
       |  Klient    |        |  Server   |        |  Klient   |
       +------------+ +----&gt; +-----------+ &lt;----+ +-----------+
                                 + ^
                                 | |
                                 v +
                             +-----------+
                             |  Klient   |
                             +-----------+</pre>

### Opis działania ###

<pre>

   +-----------------------+                                             +------------------------+
   |      SERVER           |                                             |      KLIENT            |
   |-----------------------|                                             |------------------------|
   |                       |      GET /start                             |                        |
   | Serwer sprawdza w     &lt;---------------------------------------------+ Wysłanie zapytania o   |
   | bazie ktore domeny    |                                             | URL do przeskanowania  |
   | sa jeszcze nie        |                                             |                        |
   | przeskanowane i       |     RETURN url                              |                        |
   | odsyłą pierwszą zna-  +---------------------------------------------&gt;                        |
   | lezioną               |                                             |                        |
   |                       |                               +-------------+ Klient przeszukuje po- |
   |                       |                               |             | dany URL i zapisuje    |
   |                       |                               |             | wszystkie znalezione   |
   |                       |                               |             | adresy e-mail oraz     |
   |                       |                               +-------------&gt; linki wychodzące       |
   |                       |                                             |                        |
   |                       |      POST /link                             |                        |
   |                       &lt;---------------------------------------------+ Wysyłane są zapytania  |
   |                       |                                             | POST zawierające po 10 |
   |                       |                                             | znalezionych linków    |
   |                       |      POST /email                            |                        |
   |                       &lt;---------------------------------------------+ Wysyłane są zapytania  |
   |                       |                                             | POST zawierające po 10 |
   |                       |                                             | znalezionych adresów   |
   |                       |                                             | e-mail.                |
   +-----------------------+                                             +------------------------+</pre>


### Uruchamianie ###
Program serwera uruchamiamy następująco:

    ~/chgspam$ bundle exec ruby server/server.rb # Bedac w katalogu głównym aplikacji

Program kliencki należy uruchomić podając jako argument URI serwera wraz z portem.

    ~/chgspam$ bundle exec ruby crawler/crawler.rb url_servera  # Będąc w katalogu głównym aplikacji

### Wynik działania ###
Serwer udostępnia pozyskane adresy e-mail oraz domeny pod adresami

    http://url_servera:4567/email
    htto://url_servera:4567/link

Przykładowy wynik programu przy czasie działania 10 minut: 
  
    $ curl http://0.0.0.0:4567/email -s | head -n20 
    <html>
    <body>
    <h2>429 gathered.</h2>
    <ul>
      <li>bartosz@pranczke.com</li>
    </ul>
    <ul>
      <li>ala@wp.pl</li>
    </ul>
    <ul>
      <li>fdsfsd@das.com</li>
    </ul>
    <ul>
      <li>Sekretariat.Rektora@put.poznan.pl</li>
    </ul>
    <ul>
      <li>Sekretariat.Prorektorow@put.poznan.pl</li>
    </ul>
    <ul>
      <li>Sekretariat.Kanclerza@put.poznan.pl</li>

### Protokoły ###
Serwer jest oparty o architekturę RESTfull i komunikuję się z klientem za pomocą HTTP.
Dane przesyłane są między klientem a serwerem w za pomocą formatu JSON. 

Przykładowo wysłanie zapytania GET /start do serwera zwraca:

    $ curl http://0.0.0.0:4567/start -s             
    {"domain":{"id":8,"url":"http://www.et.put.poznan.pl/","visited":null,"visited_at":"2011-11-29T01:23:29+01:00"}}% 

Pola visited oraz visited_at zostaną omówionę w punkcjie "Obsługa błędów"

### Obsługa błędów ###
Każda domena do sprawdzenia lub sprawdzona w bazie jest dodatkowo opisana dwoma polami:
  - visited
  - visited_at
Pole visited_at zostaje wypełnione w momencie wysłania URL do klienta. Natomiast pole visited oznacza, 
że sprawdzenie przebiegło pomyślne i jest ustawione w momencie, gdy klient zwraca rezultat poszukiwań
do serwera. Serwer czeka 10 minut na rezultaty od klienta, po czym uznaje, że klient zawiódł
i deleguje URL do póli do sprawdzenia.

### Maszyny wirtualne ###
Do projektu dołączona jest maszyna wirtualna z zainstalowanym klientem oraz serwerem. 
Maszyny można sklonować dowolną ilość razy. Każda maszyna może pełnić funkcję serwera
lub klienta.

Login uzytkownika: user

Hasło użytkownika: b

Hasło superużytkownika: a

Pliki projektu znajduą się w katalogu /home/user/chgspam

