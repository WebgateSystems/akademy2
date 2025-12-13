#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# AKAdemy Video Converter
# 
# Konwertuje wideo do formatu 720p H.264 z opcjonalnym logotypem i credits
#
# Użycie:
#   ./akademy-video-converter.sh <plik_wideo> [opcje]
#   ./akademy-video-converter.sh video.mp4                         # preview bez logo
#   ./akademy-video-converter.sh video.mp4 -l logo.png             # preview z logo
#   ./akademy-video-converter.sh video.mp4 -l logo.png -f          # pełne z logo
#   ./akademy-video-converter.sh video.mp4 -c credits.png          # preview + credits
#   ./akademy-video-converter.sh video.mp4 -l logo.png -c credits.png -f  # pełne
#   ./akademy-video-converter.sh -h                                # pomoc
# =============================================================================

show_help() {
  echo "AKAdemy Video Converter"
  echo ""
  echo "Użycie: $0 <plik_wideo> [OPCJE]"
  echo ""
  echo "Konwertuje wideo do 720p H.264 z opcjonalnym logotypem i credits"
  echo ""
  echo "Argumenty:"
  echo "  <plik_wideo>         Plik wideo do konwersji (wymagany)"
  echo ""
  echo "Opcje:"
  echo "  -l, --logo FILE      Plik logotypu PNG (opcjonalny)"
  echo "  -c, --credits FILE   Plik credits PNG (opcjonalny)"
  echo "  --credits-hold N     Czas pełnego wyświetlania credits w sekundach (domyślnie: 5)"
  echo "  --credits-fade N     Czas fade out credits w sekundach (domyślnie: 5)"
  echo "  --xfade N            Czas przejścia xfade do credits w sekundach (domyślnie: 1)"
  echo "  -f, --full           Konwertuj pełne wideo (domyślnie: tylko 20s preview)"
  echo "  -o, --output FILE    Nazwa pliku wyjściowego (opcjonalna)"
  echo "  -h, --help           Pokaż tę pomoc"
  echo ""
  echo "Przykłady:"
  echo "  $0 film.mp4                              # preview 20s bez logo"
  echo "  $0 film.mp4 -f                           # pełny film bez logo"
  echo "  $0 film.mp4 -l logo.png                  # preview 20s z logo"
  echo "  $0 film.mp4 -l logo.png -f               # pełny film z logo"
  echo "  $0 film.mp4 -c credits.png               # preview 20s + credits"
  echo "  $0 film.mp4 -l logo.png -c credits.png   # preview z logo + credits"
  echo "  $0 film.mp4 -l logo.png -c credits.png -f --credits-hold 7 --credits-fade 3"
}

# Domyślne wartości
FULL_MODE=false
INPUT_FILE=""
LOGO_FILE=""
CREDITS_FILE=""
OUTPUT_FILE=""
CREDITS_HOLD=5      # sekundy pełnego wyświetlania credits
CREDITS_FADE=5      # sekundy fade out
XFADE_DUR=1         # sekundy przejścia xfade

# Parsowanie argumentów
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--full)
      FULL_MODE=true
      shift
      ;;
    -l|--logo)
      LOGO_FILE="$2"
      shift 2
      ;;
    -c|--credits)
      CREDITS_FILE="$2"
      shift 2
      ;;
    --credits-hold)
      CREDITS_HOLD="$2"
      shift 2
      ;;
    --credits-fade)
      CREDITS_FADE="$2"
      shift 2
      ;;
    --xfade)
      XFADE_DUR="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    -*)
      echo "❌ Nieznana opcja: $1"
      echo ""
      show_help
      exit 1
      ;;
    *)
      if [ -z "$INPUT_FILE" ]; then
        INPUT_FILE="$1"
      else
        echo "❌ Nieoczekiwany argument: $1"
        show_help
        exit 1
      fi
      shift
      ;;
  esac
done

# Walidacja - plik wideo jest wymagany
if [ -z "$INPUT_FILE" ]; then
  echo "❌ Błąd: Nie podano pliku wideo"
  echo ""
  show_help
  exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "❌ Błąd: Plik nie istnieje: $INPUT_FILE"
  exit 1
fi

# Sprawdź czy logo istnieje (jeśli podane)
USE_LOGO=false
if [ -n "$LOGO_FILE" ]; then
  if [ ! -f "$LOGO_FILE" ]; then
    echo "❌ Błąd: Plik logotypu nie istnieje: $LOGO_FILE"
    exit 1
  fi
  USE_LOGO=true
fi

# Sprawdź czy credits istnieje (jeśli podane)
USE_CREDITS=false
if [ -n "$CREDITS_FILE" ]; then
  if [ ! -f "$CREDITS_FILE" ]; then
    echo "❌ Błąd: Plik credits nie istnieje: $CREDITS_FILE"
    exit 1
  fi
  USE_CREDITS=true
fi

# Generuj nazwę pliku wyjściowego jeśli nie podana
if [ -z "$OUTPUT_FILE" ]; then
  BASENAME=$(basename "$INPUT_FILE" | sed 's/\.[^.]*$//')
  SUFFIX=""
  [ "$USE_LOGO" = true ] && SUFFIX="${SUFFIX}-logo"
  [ "$USE_CREDITS" = true ] && SUFFIX="${SUFFIX}-credits"
  
  if [ "$FULL_MODE" = true ]; then
    OUTPUT_FILE="${BASENAME}-720p-h264${SUFFIX}.mp4"
  else
    OUTPUT_FILE="${BASENAME}-720p-h264${SUFFIX}-preview.mp4"
  fi
fi

# Tryb i czas
if [ "$FULL_MODE" = true ]; then
  PREVIEW_DUR=""
  echo "🎬 Tryb: PEŁNE WIDEO"
else
  PREVIEW_DUR="20"
  echo "🎬 Tryb: PREVIEW (20 sekund)"
fi

# Parametry wideo
W=1280
FPS=25
MARGIN=24

echo "📁 Wejście:  $INPUT_FILE"
[ "$USE_LOGO" = true ] && echo "🏷️  Logo:     $LOGO_FILE" || echo "🏷️  Logo:     (brak)"
[ "$USE_CREDITS" = true ] && echo "🎬 Credits:  $CREDITS_FILE (hold: ${CREDITS_HOLD}s, fade: ${CREDITS_FADE}s)" || echo "🎬 Credits:  (brak)"
echo "📤 Wyjście:  $OUTPUT_FILE"
echo ""

# Pobierz długość wideo źródłowego
VIDEO_DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE" | cut -d. -f1)
VIDEO_DUR=$((VIDEO_DUR + 1))

# Określ efektywną długość wideo głównego (preview lub pełne)
if [ -n "$PREVIEW_DUR" ]; then
  EFFECTIVE_DUR="$PREVIEW_DUR"
else
  EFFECTIVE_DUR="$VIDEO_DUR"
fi

# Oblicz całkowitą długość credits
CREDITS_TOTAL=$((CREDITS_HOLD + CREDITS_FADE))

# ===================================================================
# BUDOWANIE FILTRA
# ===================================================================

build_main_video_filter() {
  # Buduje filtr dla głównego wideo (z logo lub bez)
  # Wyjście: [main_video]
  
  if [ "$USE_LOGO" = true ]; then
    # Parametry fade logotypu
    FADE_START=7
    FADE_DUR=5
    ALPHA_END=0.5
    ALPHA_BOOST=$(echo "1 - $ALPHA_END" | bc)
    
    echo "[0:v]scale=${W}:-2,fps=${FPS}[vid];\
[1:v]format=rgba,loop=loop=-1:size=1,trim=duration=${EFFECTIVE_DUR}[logo_loop];\
[logo_loop]split=2[logo1][logo2];\
[logo1]colorchannelmixer=aa=${ALPHA_END}[logo_base];\
[logo2]colorchannelmixer=aa=${ALPHA_BOOST},fade=t=out:st=${FADE_START}:d=${FADE_DUR}:alpha=1[logo_boost];\
[logo_base][logo_boost]overlay=format=auto[logof];\
[vid][logof]overlay=W-w-${MARGIN}:${MARGIN}[main_video]"
  else
    echo "[0:v]scale=${W}:-2,fps=${FPS}[main_video]"
  fi
}

# ===================================================================
# KONWERSJA
# ===================================================================

if [ "$USE_CREDITS" = true ]; then
  # === Z CREDITS (dwuetapowa konwersja) ===
  
  # Oblicz parametry
  XFADE_OFFSET=$((EFFECTIVE_DUR - XFADE_DUR))
  FADEOUT_START=$((XFADE_OFFSET + CREDITS_HOLD))
  TOTAL_DUR=$((EFFECTIVE_DUR + CREDITS_TOTAL - XFADE_DUR))
  
  # Plik tymczasowy dla głównego wideo
  TEMP_DIR=$(mktemp -d)
  TEMP_MAIN="${TEMP_DIR}/main.mp4"
  trap "rm -rf '$TEMP_DIR'" EXIT
  
  echo "📹 Krok 1/2: Konwersja głównego wideo..."
  
  # KROK 1: Utwórz główne wideo (z logo lub bez)
  if [ "$USE_LOGO" = true ]; then
    FADE_START=7
    FADE_DUR_LOGO=5
    ALPHA_END=0.5
    ALPHA_BOOST=$(echo "1 - $ALPHA_END" | bc)
    
    MAIN_FILTER="[0:v]scale=${W}:-2,fps=${FPS}[vid];\
[1:v]format=rgba,loop=loop=-1:size=1,trim=duration=${EFFECTIVE_DUR}[logo_loop];\
[logo_loop]split=2[logo1][logo2];\
[logo1]colorchannelmixer=aa=${ALPHA_END}[logo_base];\
[logo2]colorchannelmixer=aa=${ALPHA_BOOST},fade=t=out:st=${FADE_START}:d=${FADE_DUR_LOGO}:alpha=1[logo_boost];\
[logo_base][logo_boost]overlay=format=auto[logof];\
[vid][logof]overlay=W-w-${MARGIN}:${MARGIN}"
    
    ffmpeg -y -i "${INPUT_FILE}" -i "${LOGO_FILE}" \
      -filter_complex "${MAIN_FILTER}" \
      -t "${EFFECTIVE_DUR}" \
      -c:v libx264 -preset slow -crf 23 \
      -profile:v high -level 4.0 -pix_fmt yuv420p \
      -c:a aac -ac 1 -b:a 64k \
      "${TEMP_MAIN}"
  else
    ffmpeg -y -i "${INPUT_FILE}" \
      -vf "scale=${W}:-2,fps=${FPS}" \
      -t "${EFFECTIVE_DUR}" \
      -c:v libx264 -preset slow -crf 23 \
      -profile:v high -level 4.0 -pix_fmt yuv420p \
      -c:a aac -ac 1 -b:a 64k \
      "${TEMP_MAIN}"
  fi
  
  echo ""
  echo "📹 Krok 2/2: Dodawanie credits z xfade..."
  
  # KROK 2: Dodaj credits z xfade i fade out
  # Używamy -loop 1 dla PNG co daje stały framerate
  # Audio: zachowujemy z głównego wideo + dodajemy ciszę dla credits (fade out audio)
  AUDIO_FADE_START=$((EFFECTIVE_DUR - 2))  # zaczynamy fade out audio 2s przed końcem wideo
  
  ffmpeg -y -i "${TEMP_MAIN}" -loop 1 -t "${CREDITS_TOTAL}" -i "${CREDITS_FILE}" \
    -filter_complex "\
[0:v]fps=${FPS},format=yuv420p[main];\
[1:v]scale=${W}:720,fps=${FPS},format=yuv420p[credits];\
[main][credits]xfade=transition=fade:duration=${XFADE_DUR}:offset=${XFADE_OFFSET}[with_credits];\
[with_credits]fade=t=out:st=${FADEOUT_START}:d=${CREDITS_FADE}[vout];\
[0:a]apad=whole_dur=${TOTAL_DUR},afade=t=out:st=${AUDIO_FADE_START}:d=3[aout]" \
    -map "[vout]" -map "[aout]" \
    -c:v libx264 -preset slow -crf 25 \
    -profile:v high -level 4.0 -pix_fmt yuv420p \
    -c:a aac -ac 1 -b:a 64k \
    -t "${TOTAL_DUR}" \
    -movflags +faststart \
    "${OUTPUT_FILE}"

else
  # === BEZ CREDITS ===
  
  if [ "$USE_LOGO" = true ]; then
    # Z logo, bez credits
    FADE_START=7
    FADE_DUR=5
    ALPHA_END=0.5
    ALPHA_BOOST=$(echo "1 - $ALPHA_END" | bc)
    
    FILTER="[0:v]scale=${W}:-2,fps=${FPS}[vid];\
[1:v]format=rgba,loop=loop=-1:size=1,trim=duration=${EFFECTIVE_DUR}[logo_loop];\
[logo_loop]split=2[logo1][logo2];\
[logo1]colorchannelmixer=aa=${ALPHA_END}[logo_base];\
[logo2]colorchannelmixer=aa=${ALPHA_BOOST},fade=t=out:st=${FADE_START}:d=${FADE_DUR}:alpha=1[logo_boost];\
[logo_base][logo_boost]overlay=format=auto[logof];\
[vid][logof]overlay=W-w-${MARGIN}:${MARGIN}"
    
    # Określ opcję czasu
    if [ -n "$PREVIEW_DUR" ]; then
      DUR_OPT="-t ${PREVIEW_DUR}"
    else
      DUR_OPT=""
    fi
    
    # shellcheck disable=SC2086
    ffmpeg -y -i "${INPUT_FILE}" -i "${LOGO_FILE}" \
      -filter_complex "${FILTER}" \
      $DUR_OPT \
      -c:v libx264 -preset slow -crf 25 \
      -profile:v high -level 4.0 -pix_fmt yuv420p \
      -c:a aac -ac 1 -b:a 64k \
      -movflags +faststart \
      "${OUTPUT_FILE}"
  else
    # Bez logo, bez credits
    FILTER="scale=${W}:-2,fps=${FPS}"
    
    if [ -n "$PREVIEW_DUR" ]; then
      DUR_OPT="-t ${PREVIEW_DUR}"
    else
      DUR_OPT=""
    fi
    
    # shellcheck disable=SC2086
    ffmpeg -y -i "${INPUT_FILE}" \
      -vf "${FILTER}" \
      $DUR_OPT \
      -c:v libx264 -preset slow -crf 25 \
      -profile:v high -level 4.0 -pix_fmt yuv420p \
      -c:a aac -ac 1 -b:a 64k \
      -movflags +faststart \
      "${OUTPUT_FILE}"
  fi
fi

echo ""
echo "✅ Gotowe: $OUTPUT_FILE"
