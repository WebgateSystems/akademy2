# EventLogger Service

Service do logowania aktywności użytkowników w systemie. Wszystkie eventy są zapisywane w tabeli `events` i widoczne w Activity Log (`/admin/events`).

## Automatyczne logowanie

### API Requests
Wszystkie żądania do API są automatycznie logowane przez `ApiRequestLogger` concern w `ApplicationApiController`. Logowane są:
- Metoda HTTP
- Ścieżka
- Status odpowiedzi
- Parametry (z wyłączeniem wrażliwych danych)
- Czas odpowiedzi w ms

### Loginy/Wylogowania
- **API Login**: Automatycznie logowane w `Api::V1::Sessions::CreateSession`
- **Web Login (Teacher)**: Automatycznie logowane w `Users::SessionsController`
- **Web Login (Student)**: Automatycznie logowane w `Users::SessionsController`
- **Admin Login**: Automatycznie logowane w `Api::V1::Sessions::CreateSession`
- **Logout**: Automatycznie logowane w odpowiednich kontrolerach sesji

### Quiz Completion
Automatycznie logowane po utworzeniu `QuizResult` przez callback `after_create`.

## Ręczne logowanie

### Video View
Gdy użytkownik ogląda wideo, wywołaj:

```ruby
EventLogger.log_video_view(
  content: content,           # Content object
  user: current_user,         # User object
  duration: 120,              # Optional: czas oglądania w sekundach
  progress: 75                # Optional: postęp w procentach
)
```

### Quiz Start
Gdy użytkownik rozpoczyna quiz:

```ruby
EventLogger.log_quiz_start(
  quiz: learning_module,      # LearningModule object (quiz)
  user: current_user
)
```

### Content Access
Gdy użytkownik uzyskuje dostęp do treści:

```ruby
EventLogger.log_content_access(
  content: content,           # Content object
  user: current_user,
  action: 'view'               # 'view', 'download', 'open', etc.
)
```

### Custom Events
Dla innych typów eventów:

```ruby
EventLogger.log(
  event_type: 'custom_event',
  user: current_user,
  school: current_user.school,  # Optional, automatycznie z user.school
  data: {
    custom_field: 'value',
    another_field: 123
  },
  client: 'web'                  # 'web', 'api', 'mobile', etc.
)
```

## Typy eventów

- `api_request` - Żądanie do API
- `user_login` - Logowanie użytkownika
- `user_logout` - Wylogowanie użytkownika
- `video_view` - Obejrzenie wideo
- `quiz_start` - Rozpoczęcie quizu
- `quiz_complete` - Ukończenie quizu
- `content_view` - Obejrzenie treści
- `content_download` - Pobranie treści
- `content_open` - Otwarcie treści

## Przykład użycia w kontrolerze API

```ruby
class Api::V1::ContentsController < ApplicationApiController
  def show
    content = Content.find(params[:id])
    
    # Log video view
    if content.content_type == 'video' && current_user
      EventLogger.log_video_view(
        content: content,
        user: current_user
      )
    end
    
    render json: ContentSerializer.new(content).serializable_hash
  end
end
```

## Przykład użycia w kontrolerze web

```ruby
class ContentsController < ApplicationController
  def show
    @content = Content.find(params[:id])
    
    if @content.content_type == 'video' && user_signed_in?
      EventLogger.log_video_view(
        content: @content,
        user: current_user
      )
    end
  end
end
```

## Uwagi

- EventLogger nie przerywa działania aplikacji w przypadku błędu - błędy są logowane do Rails.logger
- Wrażliwe dane (hasła, tokeny) są automatycznie usuwane z parametrów przed logowaniem
- Eventy są zapisywane asynchronicznie i nie powinny spowalniać głównego flow aplikacji


