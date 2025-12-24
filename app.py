import streamlit as st
from rag_app import answer

st.title("Google Cloud Release Notes Q&A")

question = st.text_input("Ask a question about the release notes:")



if question:
    with st.spinner("Thinking..."):
        response = answer(question)
    st.markdown("### Answer")
    st.write(response)
