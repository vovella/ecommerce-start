#!/usr/bin/env bash
# test_services.sh — простий тестовий скрипт для перевірки запуску після модуля 1

set -euo pipefail

echo "=== Тестування сервісів після модуля 1 ==="

# 1. Перевірка наявності ключових файлів
echo "Перевірка файлів даних..."
for file in data/products.csv data/reviews.csv data/user_queries.csv; do
    if [[ -f "$file" ]]; then
        echo "[OK] $file існує ($(wc -l < "$file") рядків)"
    else
        echo "[FAIL] $file НЕ знайдено!"
        exit 1
    fi
done

# 2. Перевірка запуску Streamlit (локально або в Docker)
echo "Перевірка запуску Streamlit..."

# Якщо Docker запущений
if docker compose ps | grep -q "Up"; then
    echo "[OK] Docker-контейнер запущений"
    curl -s -o /dev/null -w "%{http_code}" http://localhost:8501 | grep -q "200" && \
        echo "[OK] Streamlit доступний на http://localhost:8501" || \
        echo "[FAIL] Streamlit не відповідає на порту 8501"
else
    echo "Docker не запущений → тестуємо локально"
    # Перевірка, чи Streamlit встановлений
    if command -v streamlit >/dev/null 2>&1; then
        echo "[OK] Streamlit встановлений"
    else
        echo "[WARN] Streamlit не знайдено локально"
    fi
fi

# 3. Перевірка генератора (чи не падає)
echo "Перевірка генератора даних..."
python scripts/data/generate_ecommerce_data.py --products 10 --output data-test || {
    echo "[FAIL] Генератор падає!"
    exit 1
}
echo "[OK] Генератор виконався без помилок"

echo ""
echo "=== Тестування завершено ==="
echo "Якщо всі [OK] — модуль 1 готовий до здачі!"
