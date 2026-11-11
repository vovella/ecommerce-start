import streamlit as st
import pandas as pd

st.title("E-commerce Chat Agent - Basic version (Modul 1)")

@st.cache_data
def load_products():
    try:
        # Рекомендую перевірити шлях до файлу
        return pd.read_csv('data/products.csv')
    except FileNotFoundError:
        st.error("No data found. Run the data generator.!")
        return pd.DataFrame()

products = load_products()

if products.empty:
    st.warning("Load data using scripts/generate_data.py")
else:
    st.sidebar.success(f"Uploaded {len(products)} products")

# Ініціалізація історії чату
if "messages" not in st.session_state:
    st.session_state.messages = []

# Відображення історії чату (виправлено відступи)
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])

# Обробка нового вводу користувача
if prompt := st.chat_input("Ask about products (e.g. 'phone')"):
    # Додаємо повідомлення користувача в історію та показуємо його
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    # Пошук товарів
    query = prompt.lower()
    results = products[
        products['name'].str.lower().str.contains(query, na=False) |
        products['category'].str.lower().str.contains(query, na=False) |
        products['description'].str.lower().str.contains(query, na=False)
    ]

    # Формування відповіді
    if not results.empty:
        response = f"Found {len(results)} products:\n\n"
        for _, row in results.head(5).iterrows():
            response += f"- **{row['name']}** ({row['category']}) - ${row['final_price']}\n  {row['description'][:150]}...\n\n"
    else:
        response = "Nothing found. Try another query.!"

    # Додаємо відповідь асистента в історію та показуємо її
    with st.chat_message("assistant"):
        st.markdown(response)
    st.session_state.messages.append({"role": "assistant", "content": response})
