# Learning Modules - Diagrams

## ERD (Diagram Związków Encji)

```mermaid
erDiagram
    Subject ||--o{ Unit : "ma wiele"
    Unit ||--o{ LearningModule : "ma wiele"
    LearningModule ||--o{ Content : "ma wiele"
    LearningModule ||--o{ QuizResult : "ma wiele"
    LearningModule ||--o{ Certificate : "ma wiele"
    User ||--o{ QuizResult : "wykonuje"
    User ||--o{ Certificate : "otrzymuje"
    School ||--o{ Subject : "ma wiele (przyszłość)"
    
    Subject {
        uuid id PK
        uuid school_id FK "nullable (nil = globalny)"
        string title "Tytuł"
        string slug "Slug"
        integer order_index "Kolejność"
        string icon "Ikona (CarrierWave)"
        string color_light "Kolor jasny"
        string color_dark "Kolor ciemny"
    }
    
    Unit {
        uuid id PK
        uuid subject_id FK
        string title "Tytuł"
        integer order_index "Kolejność"
    }
    
    LearningModule {
        uuid id PK
        uuid unit_id FK
        string title "Tytuł"
        integer order_index "Kolejność"
        boolean published "Opublikowany"
        boolean single_flow "true=sztywna sekwencja (wszystkie w kolejności), false=dowolny wybór (dowolna liczba, kolejność, zawartość)"
    }
    
    Content {
        uuid id PK
        uuid learning_module_id FK
        string title "Tytuł"
        string content_type "video/infographic/quiz/pdf/webinar/asset"
        integer order_index "Kolejność w module"
        integer duration_sec "Czas trwania (sekundy)"
        string youtube_url "URL YouTube"
        jsonb payload "Dane JSON (quiz, subtitles)"
        string file "Plik (CarrierWave)"
        string poster "Plakat (CarrierWave)"
        string subtitles "Napisy (CarrierWave)"
    }
    
    QuizResult {
        uuid id PK
        uuid user_id FK "Uczeń"
        uuid learning_module_id FK
        integer score "Wynik (%)"
        boolean passed "Zdany"
        jsonb answers "Odpowiedzi (JSON)"
        datetime completed_at "Data ukończenia"
    }
    
    Certificate {
        uuid id PK
        uuid user_id FK "Uczeń"
        uuid learning_module_id FK
        datetime issued_at "Data wydania"
    }
```

## Hierarchia Struktury Danych

```mermaid
graph TD
    A[Subject<br/>Przedmiot] --> B[Unit<br/>Jednostka]
    B --> C[LearningModule<br/>Moduł edukacyjny<br/>single_flow: true/false]
    C --> D[Content: Video<br/>order_index: 1]
    C --> E[Content: Infographic<br/>order_index: 2]
    C --> F[Content: Quiz<br/>order_index: 3]
    C --> G[Content: PDF<br/>order_index: 4]
    C --> H[Content: Webinar<br/>order_index: 5]
    C --> I[Content: Asset<br/>order_index: 6]
    
    C --> J[QuizResult<br/>Wynik quizu]
    C --> K[Certificate<br/>Certyfikat]
    
    style A fill:#e1f5ff
    style B fill:#fff4e1
    style C fill:#e8f5e9
    style D fill:#fce4ec
    style E fill:#fce4ec
    style F fill:#fce4ec
    style G fill:#fce4ec
    style H fill:#fce4ec
    style I fill:#fce4ec
    
    Note1[Przy single_flow: false<br/>Użytkownik widzi listę Contents<br/>i wybiera dowolną liczbę<br/>w dowolnej kolejności]
    C -.-> Note1
    style Note1 fill:#fff9c4,stroke:#fbc02d
```

## Current vs Future Module Structure

```mermaid
graph LR
    subgraph Current["Obecne: 7 Globalnych Modułów"]
        A1[Subject 1<br/>Polska i świat] --> B1[Unit 1]
        B1 --> C1[Module 1<br/>single_flow: true/false]
        C1 --> D1[Contents...<br/>Video, Infografika, Quiz]
        
        A2[Subject 2<br/>Bezpieczeństwo] --> B2[Unit 2]
        B2 --> C2[Module 2<br/>single_flow: true/false]
        C2 --> D2[Contents...<br/>Video, Infografika, Quiz]
    end
    
    subgraph Future["Przyszłość: Pełny Rejestr Szkolny"]
        A3[Subject: Matematyka<br/>Specyficzne dla szkoły] --> B3[Unit: Algebra]
        A3 --> B4[Unit: Geometria]
        B3 --> C3[Module: Równania liniowe<br/>single_flow: false]
        B3 --> C4[Module: Równania kwadratowe<br/>single_flow: true]
        B4 --> C5[Module: Trójkąty<br/>single_flow: false]
        C3 --> D3[Contents...<br/>Dowolna liczba i kolejność]
    end
```

## User Flow

```mermaid
flowchart TD
    Start([Student starts]) --> SelectSubject[Wybierz Przedmiot]
    SelectSubject --> ViewUnit[Zobacz Jednostkę]
    ViewUnit --> ViewModule[Zobacz Moduł edukacyjny]
    ViewModule --> CheckFlow{Sprawdź single_flow}
    
    CheckFlow -->|true| FixedFlow[Sztywna sekwencja<br/>Wszystkie materiały<br/>w ustalonej kolejności]
    CheckFlow -->|false| FlexibleFlow[Dowolny wybór<br/>Lista wszystkich materiałów<br/>do wyboru]
    
    FixedFlow --> Video1[1. Obejrzyj Wideo<br/>obowiązkowe]
    Video1 --> Infographic1[2. Zobacz Infografikę<br/>obowiązkowe]
    Infographic1 --> Quiz1[3. Rozwiąż Quiz<br/>obowiązkowe]
    
    FlexibleFlow --> ContentList[Lista wszystkich Contents<br/>Video, Infografika, Quiz, PDF...]
    ContentList --> SelectAny[Wybierz DOWOLNĄ liczbę<br/>w DOWOLNEJ kolejności]
    SelectAny --> Video2[Wideo?<br/>opcjonalne]
    SelectAny --> Infographic2[Infografika?<br/>opcjonalne]
    SelectAny --> Quiz2[Quiz?<br/>opcjonalne]
    SelectAny --> PDF2[PDF?<br/>opcjonalne]
    SelectAny --> Other[Inne?<br/>opcjonalne]
    
    Video2 --> CheckComplete{Sprawdź<br/>czy ukończono<br/>wybrane materiały?}
    Infographic2 --> CheckComplete
    Quiz2 --> CheckComplete
    PDF2 --> CheckComplete
    Other --> CheckComplete
    Quiz1 --> CheckPass{Quiz zdany?}
    CheckComplete --> CheckPass
    
    CheckPass -->|Tak| Certificate[Otrzymaj Certyfikat]
    CheckPass -->|Nie| RetakeQuiz[Powtórz Quiz]
    RetakeQuiz --> Quiz1
    
    Certificate --> End([Zakończono])
    
    style FixedFlow fill:#ffebee
    style FlexibleFlow fill:#e8f5e9
    style ContentList fill:#e3f2fd
    style SelectAny fill:#fff3e0
```

## Mapowanie: 7 Tematów → Przedmioty Szkolne

```mermaid
mindmap
  root((7 Modułów Edukacyjnych))
    Polska i świat
      Historia
      Wiedza o społeczeństwie
      Geografia
    Bezpieczeństwo
      Bezpieczeństwo cyfrowe
      Ewakuacja
      Pierwsza pomoc
    Ekologia
      Ochrona środowiska
      Zrównoważony rozwój
      Klimat
    Zdrowie
      Zdrowy styl życia
      Żywienie
      Aktywność fizyczna
    Kultura
      Literatura
      Sztuka
      Muzyka
    Technologia
      Informatyka
      Programowanie
      Media cyfrowe
    Przedsiębiorczość
      Ekonomia
      Biznes
      Finanse
```

## Mapa Typów Treści

```mermaid
mindmap
  root((Typy Treści))
    Video
      URL YouTube
      Wgrany plik
      Obraz postera
      Napisy
      Czas trwania
    Infografika
      Plik obrazu
      SVG/PNG/PDF
    Quiz
      Payload JSON
      Pytania
      Opcje
      Poprawne odpowiedzi
      Punkty
      Próg zdania
    PDF
      Plik dokumentu
      Do pobrania
    Webinar
      Link do wideo
      Czas trwania
    Asset
      Dowolny typ pliku
      Ogólne wgrywanie
```

## Relacje Użytkownik / Wyniki

```mermaid
erDiagram
    User ||--o{ QuizResult : "wykonuje"
    User ||--o{ Certificate : "otrzymuje"
    LearningModule ||--o{ QuizResult : "ma wyniki"
    LearningModule ||--o{ Certificate : "wydaje"
    
    User {
        uuid id PK
        string first_name "Imię"
        string last_name "Nazwisko"
        string email "Email"
        uuid school_id FK "Szkoła"
    }
    
    QuizResult {
        uuid id PK
        uuid user_id FK "Uczeń"
        uuid learning_module_id FK "Moduł"
        integer score "Wynik (%)"
        boolean passed "Zdany"
        jsonb answers "Odpowiedzi"
    }
    
    Certificate {
        uuid id PK
        uuid user_id FK "Uczeń"
        uuid learning_module_id FK "Moduł"
        datetime issued_at "Data wydania"
    }
```
