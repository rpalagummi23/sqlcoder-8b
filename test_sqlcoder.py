#!/usr/bin/env python3
"""
Test script for SQLCoder-8B deployed via vLLM
This script demonstrates how to send natural language queries and get SQL back.
"""

import requests
import json

# vLLM server endpoint
VLLM_URL = "http://localhost:8000/v1/completions"

def generate_sql(question: str, schema: str) -> str:
    """
    Convert a natural language question to SQL using SQLCoder-8B.
    
    Args:
        question: Natural language question about the data
        schema: Database schema (CREATE TABLE statements)
    
    Returns:
        Generated SQL query
    """
    
    # SQLCoder prompt format
    prompt = f"""### Task
Generate a SQL query to answer [QUESTION]{question}[/QUESTION]

### Database Schema
The query will run on a database with the following schema:
{schema}

### Answer
Given the database schema, here is the SQL query that answers [QUESTION]{question}[/QUESTION]
[SQL]
"""
    
    payload = {
        "model": "defog/llama-3-sqlcoder-8b",
        "prompt": prompt,
        "max_tokens": 512,
        "temperature": 0.0,
        "stop": ["[/SQL]", "###", "\n\n"]
    }
    
    response = requests.post(VLLM_URL, json=payload)
    response.raise_for_status()
    
    result = response.json()
    sql = result["choices"][0]["text"].strip()
    
    return sql


# =============================================================================
# Example Usage
# =============================================================================

if __name__ == "__main__":
    
    # Example PostgreSQL schema
    example_schema = """
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    total_amount DECIMAL(10, 2),
    status VARCHAR(50),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(200),
    price DECIMAL(10, 2),
    category VARCHAR(100)
);

CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER,
    unit_price DECIMAL(10, 2)
);
"""

    # Test questions
    test_questions = [
        "How many customers do we have?",
        "What is the total revenue from all orders?",
        "Show me the top 5 customers by total spending",
        "List all products in the 'Electronics' category with price over 100",
        "What is the average order value per month in 2024?"
    ]
    
    print("=" * 60)
    print("SQLCoder-8B Test - Natural Language to SQL")
    print("=" * 60)
    
    for i, question in enumerate(test_questions, 1):
        print(f"\n{'─' * 60}")
        print(f"Question {i}: {question}")
        print(f"{'─' * 60}")
        
        try:
            sql = generate_sql(question, example_schema)
            print(f"Generated SQL:\n{sql}")
        except requests.exceptions.ConnectionError:
            print("❌ Error: Cannot connect to vLLM server.")
            print("   Make sure to start the server first with: ~/start_sqlcoder.sh")
            break
        except Exception as e:
            print(f"❌ Error: {e}")
    
    print("\n" + "=" * 60)
    print("Test complete!")
    print("=" * 60)

