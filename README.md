# Praktikum Pemrograman Mobile 2 — Realtime Communication

Aplikasi Flutter komprehensif untuk eksperimen modul **Realtime Communication**, mencakup implementasi dan perbandingan langsung berbagai protokol komunikasi modern: **REST API**, **Short Polling & Long Polling**, **Server-Sent Events (SSE)**, **WebSocket**, **MQTT (IoT Sensor)**, serta modul eksplorasi **WebRTC**, **gRPC Streaming**, dan **Push Notification (FCM)**.

Aplikasi ini telah dikonfigurasi langsung untuk terhubung ke **Server Praktikum Remote**:
- **Base URL:** `https://praktikum.mqtt.my.id`
- **SSE Stream:** `https://praktikum.mqtt.my.id/api/events`
- **WebSocket:** `wss://praktikum.mqtt.my.id`
- **MQTT Broker:** `broker.hivemq.com:1883`

---

## 📱 Daftar Fitur & Praktikum

### 1. Praktikum 1 — REST API (Request–Response)
- **Endpoint:** `GET /api/data` dan `POST /api/message`
- **Fitur:**
  - Pengambilan data realtime manual (`counter`, `value`, `timestamp`) dengan pelacakan latensi respons dalam milidetik.
  - Pengiriman pesan kustom ke backend melalui HTTP POST JSON payload.
  - Log aktivitas HTTP secara mendalam.
  - Membuktikan sifat stateless dan request-driven dari REST API.

### 2. Praktikum 2 — Polling & Long Polling
- **Fitur:**
  - Pilihan interval polling: 1 detik, 2 detik, atau 5 detik.
  - Start/Stop timer polling otomatis dengan pembersihan memori (dispose).
  - Penghitung total request dan pengukuran latensi jaringan per request.
  - Tabel perbandingan komparatif arsitektur Short Polling vs Long Polling.

### 3. Praktikum 3 — Server-Sent Events (SSE)
- **Library:** `flutter_http_sse: ^1.0.5`
- **Endpoint:** `https://praktikum.mqtt.my.id/api/events`
- **Fitur:**
  - Membuka dan menutup koneksi HTTP streaming satu arah secara persisten.
  - Pembaruan counter, nilai acak, dan timestamp otomatis setiap 2 detik tanpa perlu client melakukan polling berulang.
  - Log aliran event dengan indikator status koneksi (Terhubung, Menghubungkan, Terputus).

### 4. Praktikum 4 — WebSocket (Dua Arah / Full-Duplex)
- **Library:** `web_socket_channel: ^3.0.3`
- **Endpoint:** `wss://praktikum.mqtt.my.id`
- **Fitur:**
  - Koneksi dua arah persisten dengan protokol WebSocket aman (`wss://`).
  - Antarmuka chat interaktif: mengirim teks dan menerima echo/broadcast instan dari server.
  - Pengukuran Round-Trip Time (RTT latency) per pesan.
  - Riwayat bubble chat dengan timestamp pengiriman.

### 5. Praktikum 5 — MQTT untuk IoT (Publish–Subscribe)
- **Library:** `mqtt_client: ^10.14.0`
- **Broker:** `broker.hivemq.com:1883`
- **Topik Default:** `kampus/demo/sensor01`
- **Fitur:**
  - **Simulasi Dual-Role (Client A & B)** dalam satu antarmuka:
    - **Subscriber (Client A):** Menampilkan data sensor suhu yang masuk secara real-time dengan visual kartu dinamis (biru/hijau/merah) dan indikator QoS 0.
    - **Publisher (Client B):** Slider suhu interaktif (15.0°C - 45.0°C) untuk mempublikasikan payload JSON ke topik broker.
  - Log transmisi paket MQTT IN/OUT.

### 6. Praktikum 6, 7, 8 — WebRTC, gRPC & Push Notification (FCM)
- **WebRTC:** Alur signaling (SDP Offer/Answer, ICE Candidate STUN/TURN) dan perbandingan transmisi media peer-to-peer berbasis UDP/SRTP vs REST API.
- **gRPC Streaming:** Visualisasi 4 pola RPC (Unary, Server Streaming, Client Streaming, Bidirectional Streaming) serta preview schema `sensor.proto`.
- **Push Notification (FCM):** Arsitektur pendaftaran FCM token, perutean Google Play Services/APNs, pembedaan pesan foreground vs background, serta batasan mekanisme asinkron store-and-forward.
- **Matriks Komparasi:** Panduan aturan praktis (*rule of thumb*) pemilihan protokol berdasarkan kebutuhan aplikasi.

---

## 💡 Jawaban Pertanyaan Analisis Praktikum

### Analisis Praktikum 1 (REST API)
> **Pertanyaan:** *Jika nilai pada server berubah setiap dua detik, apakah tampilan Flutter otomatis berubah jika hanya menggunakan REST API? Mengapa?*
- **Jawaban:** **Tidak.** REST API mengadopsi model *request-response* yang bersifat *client-driven* dan *stateless*. Server hanya bertindak pasif dan hanya mengirim data sebagai balasan langsung dari permintaan yang diinisiasi oleh client. Setelah respons selesai dikirim, transaksi HTTP berakhir. Server tidak memiliki kemampuan untuk mem-push data secara proaktif ke Flutter tanpa adanya permintaan HTTP GET baru dari client.

### Analisis Praktikum 2 (Polling & Long Polling)
> **Pertanyaan:** *Apa yang terjadi jika interval polling diturunkan dari lima detik menjadi 200 milidetik? Pertimbangkan latensi, penggunaan jaringan, dan beban server.*
- **Jawaban:**
  1. **Latensi:** Menjadi sangat rendah (maksimal ~200ms), sehingga data di UI tampak responsif dan mendekati waktu nyata.
  2. **Penggunaan Jaringan:** Melonjak drastis hingga **25 kali lipat** (dari 12 request/menit menjadi 300 request/menit per client). Hal ini memboroskan kuota bandwidth karena overhead header HTTP (ratusan byte) dikirim berulang kali meskipun data di server belum tentu mengalami perubahan.
  3. **Beban Server & Perangkat:** Server harus melayani lonjakan *Requests Per Second (RPS)* yang sangat tinggi (misal: 1.000 user aktif = 5.000 RPS), yang dapat memicu CPU/memory spike dan request queuing. Pada perangkat mobile, hal ini menyebabkan pemborosan daya baterai (*battery drain*) karena radio seluler dipaksa tetap berada pada kondisi aktif berdaya tinggi (*DCH state*).

### Analisis Praktikum 3 (Server-Sent Events)
> **Pertanyaan:** *Mengapa SSE menarik untuk dashboard monitoring, tetapi bukan pilihan utama untuk komunikasi audio/video dua arah?*
- **Jawaban:**
  1. **Kelebihan untuk Dashboard Monitoring:** SSE menggunakan protokol HTTP standar (port 80/443), sangat mudah melewati proxy/firewall kantor/kampus tanpa konfigurasi khusus. Menjaga 1 koneksi streaming tetap terbuka untuk menerima update teks/JSON berkala, memiliki fitur rekoneksi otomatis bawaan, dan sangat hemat sumber daya untuk skenario penerimaan data satu arah (*server-to-client*).
  2. **Alasan bukan untuk Audio/Video:**
     - SSE bersifat murni *unidirectional* (hanya server ke client), sementara audio/video membutuhkan aliran bolak-balik serentak.
     - SSE mengirim data berbasis teks (UTF-8 `data: ...\n\n`), menimbulkan overhead sangat besar jika mengkodekan stream binary video beresolusi tinggi (30-60 fps).
     - SSE berjalan di atas TCP yang memiliki *Head-of-Line (HoL) blocking* (menunggu paket hilang dikirim ulang). Komunikasi audio/video memerlukan latensi sub-100ms berbasis UDP (seperti WebRTC) di mana frame yang drop lebih baik dilewati daripada menyebabkan video terhenti (*freeze*).

### Analisis Praktikum 5 (MQTT)
> **Pertanyaan:** *Mengapa MQTT sering dipilih untuk IoT dibandingkan polling REST API setiap detik?*
- **Jawaban:**
  1. **Overhead Header Sangat Kecil:** Header paket MQTT minimum hanya **2 byte**, berbanding terbalik dengan HTTP yang memerlukan ratusan byte hingga 1 KB header per transaksi.
  2. **Arsitektur Pub/Sub Terpisah (Decoupled):** Mikrokontroler sensor (ESP32/ESP8266) dan aplikasi Flutter tidak perlu saling mengetahui IP address. Keduanya hanya berkomunikasi via broker topik.
  3. **Hemat Daya & Bandwidth:** Koneksi TCP persisten dijaga dengan ping keep-alive yang sangat ringan, menghindarkan mikrokontroler dari beban berulang TCP/TLS handshake.
  4. **Fitur Khusus IoT:** Memiliki pilihan jaminan pengiriman (QoS 0, 1, 2), *Retained Message* (menyimpan data sensor terakhir untuk subscriber baru), dan *Last Will and Testament (LWT)* untuk mendeteksi perangkat offline secara instan.

### Analisis Praktikum 6 (WebRTC)
> **Pertanyaan:** *Mengapa WebRTC lebih tepat untuk video call dibandingkan mengirim gambar kamera berulang kali melalui REST API?*
- **Jawaban:**
  1. **Peer-to-Peer Langsung:** Aliran video mengalir langsung antar perangkat pengguna tanpa membebani server backend dengan beban bandwidth media bergigabyte.
  2. **Transport UDP (SRTP):** Mengeliminasi delay retransmisi TCP. Jika terjadi packet loss di jaringan seluler yang berfluktuasi, frame berikutnya langsung diputar tanpa buffering.
  3. **Media Pipeline Bawaan:** WebRTC menyertakan echo cancellation, noise suppression, adaptive bitrate, dan codec video hardware (VP8/VP9/H.264/AV1).

### Analisis Praktikum 7 (gRPC Streaming)
> **Pertanyaan:** *Dalam sistem monitoring yang mengirim ribuan pembaruan terstruktur, kapan gRPC streaming dapat lebih sesuai dibandingkan REST API?*
- **Jawaban:** gRPC Streaming sangat sesuai ketika sistem memproses volume data telemetri yang masif antar microservices/backend, karena:
  1. **Serialisasi Binary Protobuf:** Ukuran payload jauh lebih padat (hemat 60-80% dibanding JSON) dan proses parsing serialisasi sangat cepat pada CPU.
  2. **HTTP/2 Multiplexing:** Banyak stream data dapat dikirim bersamaan melalui satu koneksi TCP tanpa koneksi baru.
  3. **Kontrak Schema Kuat (Schema-First):** Definisi pesan pada file `.proto` menjamin konsistensi tipe data yang ketat.

### Analisis Praktikum 8 (Push Notification FCM)
> **Pertanyaan:** *Mengapa push notification tidak menjamin pembaruan data seketika seperti aliran WebSocket yang aktif?*
- **Jawaban:**
  1. **Mekanisme Store-and-Forward Asinkron:** FCM adalah antrean pesan perantara melalui server Google Play Services. Pesan dapat tertunda jika perangkat offline, kualitas sinyal rendah, atau server sedang menyeimbangkan antrean pengiriman.
  2. **Power Management OS (Doze Mode):** OS Android dan iOS secara agresif menidurkan proses latar belakang untuk menghemat baterai. Pesan push dengan prioritas normal dapat di-batch dan ditunda hingga jendela pemeliharaan OS tiba.
  3. **Bukan Dedicated Socket Pribadi:** WebSocket membuka soket TCP langsung antara Flutter dan backend aplikasi, sedangkan FCM menumpang pada koneksi multiplexing OS yang tidak dirancang untuk latensi sub-detik berkelanjutan.

---

## 🚀 Cara Menjalankan Aplikasi

1. **Pastikan dependency terpasang:**
   ```bash
   flutter pub get
   ```

2. **Jalankan pengujian (Unit & Widget Test):**
   ```bash
   flutter test
   ```

3. **Jalankan pada perangkat / emulator:**
   - **Windows Desktop:**
     ```bash
     flutter run -d windows
     ```
   - **Chrome Web:**
     ```bash
     flutter run -d chrome
     ```
   - **Android Emulator / Device:**
     ```bash
     flutter run -d <device-id>
     ```
