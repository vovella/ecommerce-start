"""
E-commerce Agent System - Data Generator
Generates realistic data for MLOps course project:
- Products catalog
- Customers
- Orders & transactions
- Customer support conversations
- Knowledge base documents
- Product embeddings (pre-computed)
"""

import pandas as pd
import numpy as np
import json
import random
from datetime import datetime, timedelta
from pathlib import Path
from faker import Faker
import pickle

fake = Faker()
random.seed(42)
np.random.seed(42)

# ============================================================================
# PRODUCT CATALOG
# ============================================================================

PRODUCT_CATEGORIES = {
    "Electronics": {
        "subcategories": ["Laptops", "Smartphones", "Tablets", "Accessories", "Audio", "Cameras"],
        "price_range": (50, 2000),
        "brands": ["Dell", "Apple", "Samsung", "Sony", "HP", "Lenovo", "Asus"],
        "attributes": ["RAM", "Storage", "Screen Size", "Battery Life", "Weight"]
    },
    "Clothing": {
        "subcategories": ["Men's Wear", "Women's Wear", "Kids", "Shoes", "Accessories"],
        "price_range": (20, 300),
        "brands": ["Nike", "Adidas", "Zara", "H&M", "Levi's", "Gap", "Puma"],
        "attributes": ["Size", "Color", "Material", "Fit", "Style"]
    },
    "Home & Kitchen": {
        "subcategories": ["Furniture", "Appliances", "Decor", "Kitchenware", "Bedding"],
        "price_range": (30, 1500),
        "brands": ["IKEA", "KitchenAid", "Dyson", "Philips", "Cuisinart", "OXO"],
        "attributes": ["Dimensions", "Material", "Color", "Warranty", "Energy Rating"]
    },
    "Sports & Outdoors": {
        "subcategories": ["Fitness", "Camping", "Cycling", "Water Sports", "Team Sports"],
        "price_range": (25, 800),
        "brands": ["Nike", "Adidas", "Under Armour", "The North Face", "Columbia", "REI"],
        "attributes": ["Size", "Weight", "Material", "Durability", "Weather Resistance"]
    },
    "Books & Media": {
        "subcategories": ["Fiction", "Non-Fiction", "Textbooks", "Magazines", "E-books"],
        "price_range": (10, 150),
        "brands": ["Penguin", "HarperCollins", "Simon & Schuster", "Wiley", "O'Reilly"],
        "attributes": ["Pages", "Format", "Language", "Edition", "Publisher"]
    }
}

def generate_products(n_products=500):
    """Generate realistic product catalog"""
    products = []
    
    for i in range(n_products):
        category = random.choice(list(PRODUCT_CATEGORIES.keys()))
        cat_info = PRODUCT_CATEGORIES[category]
        
        subcategory = random.choice(cat_info["subcategories"])
        brand = random.choice(cat_info["brands"])
        
        # Generate product name
        product_type = random.choice([
            "Premium", "Professional", "Classic", "Modern", "Essential",
            "Pro", "Plus", "Ultra", "Elite", "Standard"
        ])
        
        name = f"{brand} {product_type} {subcategory}"
        
        # Price with some variation
        min_price, max_price = cat_info["price_range"]
        base_price = random.uniform(min_price, max_price)
        
        # Add seasonal discount probability
        has_discount = random.random() < 0.25
        discount = random.choice([5, 10, 15, 20, 25, 30]) if has_discount else 0
        final_price = round(base_price * (1 - discount/100), 2)
        
        # Generate realistic attributes
        attributes = {}
        for attr in random.sample(cat_info["attributes"], min(3, len(cat_info["attributes"]))):
            if attr == "Size":
                attributes[attr] = random.choice(["S", "M", "L", "XL", "XXL"])
            elif attr == "Color":
                attributes[attr] = fake.color_name()
            elif attr == "Storage":
                attributes[attr] = random.choice(["256GB", "512GB", "1TB", "2TB"])
            elif attr == "RAM":
                attributes[attr] = random.choice(["8GB", "16GB", "32GB", "64GB"])
            elif attr == "Weight":
                attributes[attr] = f"{random.uniform(0.5, 5):.1f} kg"
            else:
                attributes[attr] = fake.word().capitalize()
        
        # Generate description
        description = f"{name} - {fake.catch_phrase()}. {fake.sentence(nb_words=15)}"
        
        # Stock and ratings
        stock = random.randint(0, 500)
        rating = round(random.uniform(3.0, 5.0), 1)
        num_reviews = random.randint(0, 1000) if rating > 4.0 else random.randint(0, 100)
        
        # Tags for search
        tags = [category, subcategory, brand] + random.sample(
            ["bestseller", "new", "trending", "sale", "featured", "eco-friendly"],
            k=random.randint(0, 3)
        )
        
        product = {
            "product_id": f"PROD-{i+1:05d}",
            "name": name,
            "category": category,
            "subcategory": subcategory,
            "brand": brand,
            "base_price": round(base_price, 2),
            "discount_percent": discount,
            "final_price": final_price,
            "currency": "USD",
            "stock_quantity": stock,
            "in_stock": stock > 0,
            "rating": rating,
            "num_reviews": num_reviews,
            "description": description,
            "attributes": json.dumps(attributes),
            "tags": ",".join(tags),
            "created_date": fake.date_between(start_date="-2y", end_date="-6m"),
            "updated_date": fake.date_between(start_date="-6m", end_date="today")
        }
        
        products.append(product)
    
    return pd.DataFrame(products)


# ============================================================================
# CUSTOMERS
# ============================================================================

def generate_customers(n_customers=5000):
    """Generate customer profiles"""
    customers = []
    
    for i in range(n_customers):
        signup_date = fake.date_between(start_date="-3y", end_date="today")
        
        # Customer segments
        segment = random.choices(
            ["high_value", "regular", "occasional", "new"],
            weights=[0.10, 0.40, 0.35, 0.15]
        )[0]
        
        # Behavior based on segment
        if segment == "high_value":
            total_orders = random.randint(50, 200)
            total_spent = random.uniform(5000, 50000)
            avg_order = total_spent / total_orders
        elif segment == "regular":
            total_orders = random.randint(10, 50)
            total_spent = random.uniform(1000, 5000)
            avg_order = total_spent / total_orders
        elif segment == "occasional":
            total_orders = random.randint(2, 10)
            total_spent = random.uniform(100, 1000)
            avg_order = total_spent / total_orders
        else:  # new
            total_orders = random.randint(0, 2)
            total_spent = random.uniform(0, 200)
            avg_order = total_spent / max(total_orders, 1)
        
        # Preferences
        preferred_categories = random.sample(
            list(PRODUCT_CATEGORIES.keys()),
            k=random.randint(1, 3)
        )
        
        customer = {
            "customer_id": f"CUST-{i+1:06d}",
            "name": fake.name(),
            "email": fake.email(),
            "phone": fake.phone_number(),
            "country": fake.country(),
            "city": fake.city(),
            "signup_date": signup_date,
            "last_login": fake.date_between(start_date=signup_date, end_date="today"),
            "segment": segment,
            "total_orders": total_orders,
            "total_spent": round(total_spent, 2),
            "average_order_value": round(avg_order, 2),
            "preferred_categories": ",".join(preferred_categories),
            "is_premium": random.random() < 0.15,
            "email_subscribed": random.random() < 0.60,
            "churn_risk": random.choices(["low", "medium", "high"], weights=[0.6, 0.3, 0.1])[0]
        }
        
        customers.append(customer)
    
    return pd.DataFrame(customers)


# ============================================================================
# ORDERS & TRANSACTIONS
# ============================================================================

def generate_orders(df_customers, df_products, n_orders=10000):
    """Generate order history"""
    orders = []
    order_items = []
    
    for i in range(n_orders):
        # Select customer
        customer = df_customers.sample(1).iloc[0]
        
        # Order date between signup and now
        order_date = fake.date_time_between(
            start_date=customer['signup_date'],
            end_date='now'
        )
        
        # Number of items
        num_items = random.choices([1, 2, 3, 4, 5], weights=[0.5, 0.25, 0.15, 0.08, 0.02])[0]
        
        # Select products (prefer customer's preferred categories)
        preferred_cats = customer['preferred_categories'].split(',')
        
        if random.random() < 0.7 and preferred_cats:
            # 70% from preferred categories
            available_products = df_products[df_products['category'].isin(preferred_cats)]
        else:
            available_products = df_products
        
        selected_products = available_products.sample(min(num_items, len(available_products)))
        
        # Calculate totals
        subtotal = selected_products['final_price'].sum()
        tax = round(subtotal * 0.08, 2)
        shipping = 0 if subtotal > 50 else 9.99
        total = round(subtotal + tax + shipping, 2)
        
        # Order status
        days_since_order = (datetime.now() - order_date).days
        
        if days_since_order < 2:
            status = random.choice(["pending", "processing"])
        elif days_since_order < 7:
            status = random.choice(["shipped", "in_transit"])
        else:
            status = random.choices(
                ["delivered", "cancelled", "returned"],
                weights=[0.85, 0.10, 0.05]
            )[0]
        
        order = {
            "order_id": f"ORD-{i+1:07d}",
            "customer_id": customer['customer_id'],
            "order_date": order_date,
            "status": status,
            "num_items": num_items,
            "subtotal": round(subtotal, 2),
            "tax": tax,
            "shipping": shipping,
            "total": total,
            "payment_method": random.choice(["credit_card", "debit_card", "paypal", "apple_pay"]),
            "shipping_address": f"{fake.street_address()}, {fake.city()}, {fake.country()}",
            "delivery_date": order_date + timedelta(days=random.randint(2, 10)) if status == "delivered" else None
        }
        
        orders.append(order)
        
        # Order items
        for _, product in selected_products.iterrows():
            quantity = random.choices([1, 2, 3], weights=[0.8, 0.15, 0.05])[0]
            
            item = {
                "order_id": order["order_id"],
                "product_id": product['product_id'],
                "product_name": product['name'],
                "quantity": quantity,
                "unit_price": product['final_price'],
                "total_price": round(product['final_price'] * quantity, 2)
            }
            
            order_items.append(item)
    
    return pd.DataFrame(orders), pd.DataFrame(order_items)


# ============================================================================
# CUSTOMER SUPPORT CONVERSATIONS
# ============================================================================

SUPPORT_TEMPLATES = {
    "product_inquiry": [
        "Hi, I'm looking for {product_type}. Can you help me find something with {feature}?",
        "Do you have {product_type} that {requirement}? What would you recommend?",
        "I need a {product_type} for {use_case}. What are my options?",
    ],
    "order_status": [
        "Hi, I placed order {order_id} {days} days ago. Can you check the status?",
        "Where is my order {order_id}? It's been {days} days and I haven't received it.",
        "I need an update on order {order_id}. When will it arrive?",
    ],
    "return_request": [
        "I want to return {product}. It doesn't meet my expectations.",
        "How do I return {product}? The {issue} doesn't work as advertised.",
        "I received {product} but it has {defect}. Can I get a refund?",
    ],
    "technical_issue": [
        "I'm having trouble with {product}. The {component} is not working.",
        "{product} stopped working after {time_period}. What should I do?",
        "Need help with {product}. Getting error: {error_message}.",
    ],
    "price_inquiry": [
        "I saw {product} was ${old_price} last week, now it's ${new_price}. Why?",
        "Is there a discount on {product}? I'm interested in buying multiple.",
        "Can you match the price I saw on {competitor} for {product}?",
    ],
    "recommendation": [
        "I'm looking for {product_type} under ${budget}. What do you recommend?",
        "Can you suggest {product_type} for someone who {description}?",
        "I need a gift for {occasion}. Budget is ${budget}. Ideas?",
    ]
}

AGENT_RESPONSES = {
    "product_inquiry": [
        "I'd be happy to help! Based on your needs, I recommend {recommendation}. It has {features} and is rated {rating}/5 by customers.",
        "Great question! We have several options. The {product} would be perfect because {reason}. Would you like more details?",
        "Let me search our catalog... I found {count} products matching your criteria. The most popular is {product}.",
    ],
    "order_status": [
        "Let me check that for you... Your order {order_id} is currently {status}. Expected delivery: {date}.",
        "I see your order {order_id} was shipped on {date} via {carrier}. Tracking: {tracking}.",
        "Your order {order_id} is {status}. I've expedited it and you should receive it by {date}. Sorry for the delay!",
    ],
    "return_request": [
        "I'm sorry to hear that. I've initiated a return for {product}. Return label sent to {email}. Refund will process in 3-5 days.",
        "I understand your frustration. Let's process your return. We'll send a prepaid label and issue a full refund once we receive it.",
        "I apologize for the inconvenience. I've created a return request. You can also choose an exchange if you prefer?",
    ],
    "technical_issue": [
        "Let's troubleshoot this. First, try {step1}. If that doesn't work, {step2}. I'll also send detailed instructions to your email.",
        "I'm sorry you're experiencing this. Based on the issue, I recommend {solution}. If it persists, we'll replace it under warranty.",
        "That sounds like {diagnosis}. Here's how to fix it: {solution}. Let me know if you need further assistance!",
    ],
    "price_inquiry": [
        "The price change is due to {reason}. However, I can offer you {discount}% off if you purchase today!",
        "Great news! We have a bulk discount available. For {quantity}+ items, you get {discount}% off. Interested?",
        "While we can't match that exact price, I can offer you {alternative}. Would that work for you?",
    ],
    "recommendation": [
        "Based on your budget and needs, I'd recommend {product1} or {product2}. {product1} is {comparison}.",
        "Perfect! I have some great options: {list}. My personal favorite is {favorite} because {reason}.",
        "Great choice for {occasion}! I suggest {product}. It's {price}, well-reviewed, and {special_feature}.",
    ]
}

def generate_support_conversations(df_customers, df_products, df_orders, n_conversations=2000):
    """Generate realistic customer support conversations"""
    conversations = []
    
    for i in range(n_conversations):
        # Select customer
        customer = df_customers.sample(1).iloc[0]
        
        # Issue type
        issue_type = random.choice(list(SUPPORT_TEMPLATES.keys()))
        
        # Generate customer message
        template = random.choice(SUPPORT_TEMPLATES[issue_type])
        
        # Fill template with realistic data
        if issue_type == "product_inquiry":
            category = random.choice(list(PRODUCT_CATEGORIES.keys()))
            product_type = random.choice(PRODUCT_CATEGORIES[category]["subcategories"])
            message = template.format(
                product_type=product_type.lower(),
                feature=random.choice(["good battery life", "high quality", "under $500", "5-star rating"]),
                requirement=random.choice(["fits my budget", "works for gaming", "is portable", "has warranty"]),
                use_case=random.choice(["work", "school", "travel", "gift"])
            )
        elif issue_type == "order_status":
            if len(df_orders) > 0:
                customer_orders = df_orders[df_orders['customer_id'] == customer['customer_id']]
                if len(customer_orders) > 0:
                    order = customer_orders.sample(1).iloc[0]
                    days = random.randint(3, 15)
                    message = template.format(order_id=order['order_id'], days=days)
                else:
                    # Customer has no orders, skip this conversation
                    continue
            else:
                continue
        elif issue_type == "return_request":
            product = df_products.sample(1).iloc[0]
            message = template.format(
                product=product['name'],
                issue=random.choice(["quality", "size", "color", "functionality"]),
                defect=random.choice(["a scratch", "missing parts", "wrong color", "damage"])
            )
        elif issue_type == "technical_issue":
            product = df_products[df_products['category'] == 'Electronics'].sample(1).iloc[0]
            message = template.format(
                product=product['name'],
                component=random.choice(["screen", "battery", "charger", "button"]),
                time_period=random.choice(["2 days", "a week", "a month"]),
                error_message=random.choice(["Won't turn on", "Keeps crashing", "Not charging"])
            )
        elif issue_type == "price_inquiry":
            product = df_products.sample(1).iloc[0]
            message = template.format(
                product=product['name'],
                old_price=round(product['base_price'], 2),
                new_price=round(product['final_price'], 2),
                competitor=random.choice(["Amazon", "Best Buy", "Walmart"])
            )
        else:  # recommendation
            category = random.choice(list(PRODUCT_CATEGORIES.keys()))
            product_type = PRODUCT_CATEGORIES[category]["subcategories"][0]
            message = template.format(
                product_type=product_type.lower(),
                budget=random.choice([100, 200, 500, 1000]),
                description=random.choice(["travels a lot", "works from home", "is a student", "loves tech"]),
                occasion=random.choice(["birthday", "anniversary", "graduation", "holiday"])
            )
        
        # Generate agent response
        response_template = random.choice(AGENT_RESPONSES[issue_type])
        
        # Fill response template
        if issue_type == "product_inquiry":
            recommended = df_products[df_products['category'] == category].sample(1).iloc[0]
            response = response_template.format(
                recommendation=recommended['name'],
                features=random.choice(["excellent performance", "great value", "top ratings"]),
                rating=recommended['rating'],
                product=recommended['name'],
                reason=random.choice(["it matches your needs", "it's within budget", "it's highly rated"]),
                count=random.randint(5, 20)
            )
        elif issue_type == "order_status":
            response = response_template.format(
                order_id=order['order_id'],
                status=order['status'],
                date=fake.date_between(start_date='today', end_date='+7d'),
                carrier=random.choice(["FedEx", "UPS", "USPS", "DHL"]),
                tracking=f"{random.randint(1000000000, 9999999999)}"
            )
        elif issue_type == "return_request":
            response = response_template.format(
                product=product['name'],
                email=customer['email']
            )
        elif issue_type == "technical_issue":
            response = response_template.format(
                step1="restarting the device",
                step2="checking for updates",
                solution=random.choice(["reset to factory settings", "update firmware", "contact manufacturer"]),
                diagnosis=random.choice(["a software issue", "hardware malfunction", "compatibility issue"])
            )
        elif issue_type == "price_inquiry":
            response = response_template.format(
                reason=random.choice(["a promotion ending", "market changes", "high demand"]),
                discount=random.choice([5, 10, 15]),
                quantity=random.choice([3, 5, 10]),
                alternative="free shipping and extended warranty"
            )
        else:  # recommendation
            recommended = df_products.sample(min(3, len(df_products)))
            response = response_template.format(
                product1=recommended.iloc[0]['name'] if len(recommended) > 0 else "Sample Product",
                product2=recommended.iloc[1]['name'] if len(recommended) > 1 else "Another Product",
                comparison="better value for money",
                list=", ".join([p['name'] for _, p in recommended.iterrows()]),
                favorite=recommended.iloc[0]['name'],
                reason=random.choice(["of the quality", "it's popular", "great reviews"]),
                product=recommended.iloc[0]['name'],
                price=f"${recommended.iloc[0]['final_price']}",
                special_feature=random.choice(["comes with warranty", "free shipping", "on sale"]),
                occasion=random.choice(["this occasion", "anyone", "that special someone"])
            )
        
        # Metadata
        conversation_date = fake.date_time_between(start_date='-6m', end_date='now')
        resolution_time = random.randint(5, 120)  # minutes
        
        # Sentiment & outcome
        sentiment = random.choices(
            ["positive", "neutral", "negative"],
            weights=[0.6, 0.3, 0.1]
        )[0]
        
        outcome = random.choices(
            ["resolved", "escalated", "pending"],
            weights=[0.75, 0.15, 0.10]
        )[0]
        
        satisfaction = random.randint(3, 5) if outcome == "resolved" else random.randint(1, 3)
        
        conversation = {
            "conversation_id": f"CONV-{i+1:06d}",
            "customer_id": customer['customer_id'],
            "date": conversation_date,
            "channel": random.choice(["chat", "email", "phone"]),
            "issue_type": issue_type,
            "customer_message": message,
            "agent_message": response,
            "agent_id": f"AGT-{random.randint(1, 50):03d}",
            "sentiment": sentiment,
            "outcome": outcome,
            "resolution_time_minutes": resolution_time,
            "satisfaction_score": satisfaction,
            "follow_up_needed": random.random() < 0.15
        }
        
        conversations.append(conversation)
    
    return pd.DataFrame(conversations)


# ============================================================================
# KNOWLEDGE BASE
# ============================================================================

def generate_knowledge_base():
    """Generate knowledge base articles for RAG"""
    
    kb_articles = [
        {
            "doc_id": "KB-001",
            "category": "shipping",
            "title": "Shipping Policy and Delivery Times",
            "content": """
Our Shipping Policy:

Standard Shipping (5-7 business days):
- Free on orders over $50
- $9.99 flat rate for orders under $50
- Available nationwide

Express Shipping (2-3 business days):
- $19.99 flat rate
- Order before 2 PM for same-day processing

Overnight Shipping (next business day):
- $29.99 flat rate
- Order before 12 PM for next-day delivery
- Not available on weekends

International Shipping:
- Available to 50+ countries
- 7-14 business days
- Customs fees may apply
- Calculated at checkout

Tracking:
- Tracking number sent via email within 24 hours of shipment
- Track at track.ourstore.com
- Contact support if tracking not updated within 48 hours

Delivery Issues:
- Lost packages: Contact support after 10 business days
- Damaged items: Report within 48 hours of delivery
- Wrong address: Update within 2 hours of order placement
            """,
            "tags": "shipping,delivery,tracking,international",
            "views": random.randint(1000, 10000),
            "helpful_votes": random.randint(100, 1000)
        },
        {
            "doc_id": "KB-002",
            "category": "returns",
            "title": "Return and Refund Policy",
            "content": """
Return Policy:

30-Day Return Window:
- Items can be returned within 30 days of delivery
- Must be in original condition with tags attached
- Original packaging preferred but not required

Return Process:
1. Log into your account
2. Go to Orders → Select item → Request Return
3. Print prepaid return label (emailed within 24 hours)
4. Drop off at any carrier location
5. Refund processed within 3-5 business days after receipt

Refund Methods:
- Original payment method (3-5 business days)
- Store credit (instant)
- Exchange for different item (free)

Non-Returnable Items:
- Final sale items (marked clearly)
- Opened software or digital products
- Personal care items
- Custom-made products

Damaged or Defective Items:
- Report within 48 hours of delivery
- Photos required for claim
- Free return shipping provided
- Full refund or replacement

Restocking Fee:
- None for most items
- 15% for opened electronics
- Waived for defective items
            """,
            "tags": "returns,refunds,exchanges,policy",
            "views": random.randint(5000, 15000),
            "helpful_votes": random.randint(500, 2000)
        },
        {
            "doc_id": "KB-003",
            "category": "products",
            "title": "Product Warranty and Support",
            "content": """
Warranty Information:

Manufacturer Warranty:
- Included with all products
- Duration varies by manufacturer (typically 1-2 years)
- Covers manufacturing defects
- Requires proof of purchase

Extended Warranty:
- Available at checkout for electronics
- Extends coverage 2-3 additional years
- Covers accidental damage
- No deductible

Warranty Claims:
1. Contact our support team
2. Provide order number and issue description
3. Troubleshooting assistance provided
4. Repair, replacement, or refund if applicable

Technical Support:
- Free lifetime technical support
- Available via chat, email, or phone
- Average response time: under 2 hours
- 24/7 for premium members

Product Registration:
- Register products at register.ourstore.com
- Speeds up warranty claims
- Eligible for exclusive offers
- Product recall notifications

Common Coverage:
- Electronics: Hardware failures, screen defects
- Appliances: Motor issues, electrical problems
- Clothing: Manufacturing defects, stitching issues
- Furniture: Structural defects, material issues
            """,
            "tags": "warranty,support,technical,coverage",
            "views": random.randint(2000, 8000),
            "helpful_votes": random.randint(200, 1000)
        },
        {
            "doc_id": "KB-004",
            "category": "account",
            "title": "Account Management and Security",
            "content": """
Account Management:

Creating an Account:
- Click "Sign Up" at top right
- Provide email and create password
- Verify email address
- Start shopping!

Account Benefits:
- Faster checkout
- Order history and tracking
- Saved addresses and payment methods
- Wishlist and favorites
- Exclusive member offers
- Early access to sales

Password Reset:
1. Click "Forgot Password"
2. Enter registered email
3. Check email for reset link (valid 1 hour)
4. Create new password

Security Features:
- Two-factor authentication available
- Secure checkout (SSL encrypted)
- Payment info never stored (tokenized)
- Regular security audits

Account Settings:
- Update personal information
- Manage payment methods
- Set communication preferences
- View purchase history
- Download data

Privacy:
- We never sell your data
- See Privacy Policy for details
- Control marketing preferences
- GDPR and CCPA compliant

Deleting Account:
- Contact support to request deletion
- Data removed within 30 days
- Some order records retained for legal requirements
            """,
            "tags": "account,security,privacy,password",
            "views": random.randint(3000, 10000),
            "helpful_votes": random.randint(300, 1500)
        },
        {
            "doc_id": "KB-005",
            "category": "payment",
            "title": "Payment Methods and Billing",
            "content": """
Accepted Payment Methods:

Credit/Debit Cards:
- Visa, Mastercard, American Express, Discover
- 3D Secure authentication for security
- Save cards for future purchases (optional)

Digital Wallets:
- PayPal
- Apple Pay
- Google Pay
- Shop Pay

Other Methods:
- Gift cards and store credit
- Buy now, pay later (Klarna, Afterpay)
- Bank transfer (for large orders)

Payment Security:
- PCI DSS compliant
- Encrypted transactions
- Fraud detection systems
- Never store full card numbers

Billing:
- Charged when order ships
- Pre-authorization hold when ordered
- Billing address must match card
- Separate invoices for multiple shipments

Currency:
- Prices in USD
- International cards accepted
- Currency conversion at checkout
- No foreign transaction fees from us

Failed Payments:
- Order automatically cancelled
- Email notification sent
- Retry within 24 hours
- Contact support if issue persists

Refunds:
- Processed to original payment method
- 3-5 business days for cards
- Instant for store credit
- PayPal: 1-2 business days
            """,
            "tags": "payment,billing,security,methods",
            "views": random.randint(4000, 12000),
            "helpful_votes": random.randint(400, 1800)
        },
        {
            "doc_id": "KB-006",
            "category": "promotions",
            "title": "Discounts, Coupons, and Promotions",
            "content": """
Current Promotions:

Seasonal Sales:
- Spring Sale: March-April (up to 50% off)
- Summer Clearance: July-August (up to 70% off)
- Black Friday: November (60-80% off select items)
- Holiday Sale: December (40-60% off)

Ongoing Discounts:
- Student discount: 15% off with valid ID
- Military discount: 20% off year-round
- Senior discount: 10% off (55+)
- Healthcare workers: 15% off

Coupon Usage:
- One coupon per order
- Cannot combine with other discounts
- Enter at checkout
- Check expiration date
- Some exclusions apply

Email Newsletter:
- Subscribe for 10% off first order
- Exclusive subscriber-only deals
- Early access to sales
- New product announcements

Loyalty Program:
- Earn 1 point per dollar spent
- 100 points = $5 reward
- Birthday bonus: 200 points
- Free shipping for members
- Exclusive member sales

Price Match:
- Match competitor prices (conditions apply)
- Must be identical product
- Provide proof (link or ad)
- Valid within 7 days of purchase
- Contact support with details

Referral Program:
- Refer friends, get $20 credit
- Friend gets 15% off first order
- No limit on referrals
- Credit applied after friend's first purchase
            """,
            "tags": "discounts,promotions,coupons,loyalty",
            "views": random.randint(10000, 25000),
            "helpful_votes": random.randint(1000, 3000)
        },
        {
            "doc_id": "KB-007",
            "category": "products",
            "title": "Product Selection Guide - Electronics",
            "content": """
Electronics Buying Guide:

Laptops:
Budget ($300-600):
- Chromebooks for basic tasks
- Entry-level Windows for students
- 4-8GB RAM, 128-256GB storage

Mid-Range ($600-1200):
- Work and productivity
- 8-16GB RAM, 256-512GB SSD
- Intel i5/AMD Ryzen 5
- Good for light gaming

Premium ($1200+):
- Content creation, gaming
- 16-32GB RAM, 512GB-1TB SSD
- Intel i7/i9, AMD Ryzen 7/9
- Dedicated graphics

Smartphones:
Features to Consider:
- Camera quality (MP rating, night mode)
- Battery life (4000mAh+ recommended)
- Storage (128GB minimum recommended)
- 5G capability
- Screen size and quality

Top Picks by Use Case:
- Photography: iPhone Pro, Samsung Galaxy S
- Gaming: ROG Phone, iPhone Pro Max
- Budget: Google Pixel A, Samsung A series
- Battery life: Samsung M series, Moto G Power

Accessories:
Essential:
- Screen protector
- Protective case
- Fast charger (20W+)
- USB-C cable backup

Nice to Have:
- Wireless earbuds
- Power bank
- Car mount
- Wireless charging pad

Warranty Recommendations:
- Always get extended warranty for laptops
- AppleCare+ recommended for Apple products
- Screen protection plans for smartphones
- Accidental damage coverage for premium items
            """,
            "tags": "electronics,laptops,smartphones,guide",
            "views": random.randint(8000, 20000),
            "helpful_votes": random.randint(800, 2500)
        },
        {
            "doc_id": "KB-008",
            "category": "troubleshooting",
            "title": "Common Issues and Solutions",
            "content": """
Troubleshooting Common Issues:

Order Issues:

Order Not Received:
1. Check tracking number in email
2. Verify delivery address
3. Check with neighbors/front desk
4. Wait 1-2 extra days (carrier delays)
5. Contact support after 10 business days

Wrong Item Received:
1. Don't open if obviously wrong
2. Take photos of package and items
3. Contact support immediately
4. Free return label provided
5. Correct item shipped priority

Damaged Package:
1. Document damage with photos
2. Don't discard packaging
3. Report within 48 hours
4. Support will arrange replacement/refund
5. No return shipping cost

Website/App Issues:

Can't Log In:
- Clear browser cache/cookies
- Try different browser
- Check Caps Lock
- Reset password
- Disable VPN temporarily

Payment Declined:
- Verify card details
- Check billing address matches
- Ensure sufficient funds
- Try different payment method
- Contact your bank (may be fraud hold)

Discount Code Not Working:
- Check expiration date
- Verify minimum purchase requirement
- One code per order rule
- Some items excluded
- Contact support for help

Product Not Available:
- Sign up for back-in-stock notification
- Check similar items
- Consider alternative brands
- Pre-order if available
- Ask support for ETA

Slow Website:
- Clear cache
- Check internet connection
- Try incognito mode
- Use app instead
- Report to support if persists
            """,
            "tags": "troubleshooting,issues,solutions,help",
            "views": random.randint(15000, 35000),
            "helpful_votes": random.randint(1500, 4000)
        }
    ]
    
    return pd.DataFrame(kb_articles)


# ============================================================================
# PRODUCT EMBEDDINGS (MOCK)
# ============================================================================

def generate_product_embeddings(df_products):
    """Generate mock embeddings for products (for RAG demo)"""
    # In production, these would be real embeddings from sentence-transformers
    # For course purposes, we generate random vectors that can be used in demos
    
    embeddings = {}
    embedding_dim = 384  # all-MiniLM-L6-v2 dimension
    
    for _, product in df_products.iterrows():
        # Generate random embedding (in production, use actual model)
        embedding = np.random.randn(embedding_dim).astype(np.float32)
        # Normalize
        embedding = embedding / np.linalg.norm(embedding)
        embeddings[product['product_id']] = embedding
    
    return embeddings


# ============================================================================
# MAIN ORCHESTRATION
# ============================================================================

def generate_all_data(
    n_products=500,
    n_customers=5000,
    n_orders=10000,
    n_conversations=2000,
    output_dir="data"
):
    """Generate complete e-commerce dataset"""
    
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    print("=" * 70)
    print("🛒 E-COMMERCE AGENT SYSTEM - DATA GENERATOR")
    print("=" * 70)
    
    # 1. Products
    print("\n📦 [1/6] Generating product catalog...")
    df_products = generate_products(n_products)
    products_file = output_path / "products.csv"
    df_products.to_csv(products_file, index=False)
    print(f"   ✓ Generated {len(df_products):,} products → {products_file}")
    
    # Also save as JSON for RAG service
    products_json = output_path / "products.json"
    df_products.to_json(products_json, orient='records', indent=2)
    print(f"   ✓ Saved JSON version → {products_json}")
    
    # Category distribution
    print(f"\n   Product distribution by category:")
    print(df_products['category'].value_counts().to_string())
    
    # 2. Customers
    print("\n👥 [2/6] Generating customer profiles...")
    df_customers = generate_customers(n_customers)
    customers_file = output_path / "customers.csv"
    df_customers.to_csv(customers_file, index=False)
    print(f"   ✓ Generated {len(df_customers):,} customers → {customers_file}")
    
    print(f"\n   Customer segments:")
    print(df_customers['segment'].value_counts().to_string())
    
    # 3. Orders
    print("\n🛍️ [3/6] Generating order history...")
    df_orders, df_order_items = generate_orders(df_customers, df_products, n_orders)
    orders_file = output_path / "orders.csv"
    order_items_file = output_path / "order_items.csv"
    df_orders.to_csv(orders_file, index=False)
    df_order_items.to_csv(order_items_file, index=False)
    print(f"   ✓ Generated {len(df_orders):,} orders → {orders_file}")
    print(f"   ✓ Generated {len(df_order_items):,} order items → {order_items_file}")
    
    print(f"\n   Order status distribution:")
    print(df_orders['status'].value_counts().to_string())
    
    total_revenue = df_orders['total'].sum()
    avg_order_value = df_orders['total'].mean()
    print(f"\n   Total revenue: ${total_revenue:,.2f}")
    print(f"   Average order value: ${avg_order_value:.2f}")
    
    # 4. Support conversations
    print("\n💬 [4/6] Generating customer support conversations...")
    df_conversations = generate_support_conversations(
        df_customers, df_products, df_orders, n_conversations
    )
    conversations_file = output_path / "support_conversations.csv"
    df_conversations.to_csv(conversations_file, index=False)
    print(f"   ✓ Generated {len(df_conversations):,} conversations → {conversations_file}")
    
    print(f"\n   Issue type distribution:")
    print(df_conversations['issue_type'].value_counts().to_string())
    
    print(f"\n   Outcome distribution:")
    print(df_conversations['outcome'].value_counts().to_string())
    
    avg_resolution = df_conversations['resolution_time_minutes'].mean()
    print(f"\n   Average resolution time: {avg_resolution:.1f} minutes")
    
    # 5. Knowledge base
    print("\n📚 [5/6] Generating knowledge base...")
    df_kb = generate_knowledge_base()
    kb_file = output_path / "knowledge_base.csv"
    kb_json_file = output_path / "knowledge_base.json"
    df_kb.to_csv(kb_file, index=False)
    df_kb.to_json(kb_json_file, orient='records', indent=2)
    print(f"   ✓ Generated {len(df_kb)} KB articles → {kb_file}")
    print(f"   ✓ Saved JSON version → {kb_json_file}")
    
    print(f"\n   KB categories:")
    print(df_kb['category'].value_counts().to_string())
    
    # 6. Product embeddings
    print("\n🔢 [6/6] Generating product embeddings...")
    embeddings = generate_product_embeddings(df_products)
    embeddings_file = output_path / "product_embeddings.pkl"
    
    with open(embeddings_file, 'wb') as f:
        pickle.dump(embeddings, f)
    
    print(f"   ✓ Generated {len(embeddings):,} embeddings (384-dim) → {embeddings_file}")
    print(f"   ✓ Size: {embeddings_file.stat().st_size / 1024 / 1024:.1f} MB")
    
    # Summary statistics
    print("\n" + "=" * 70)
    print("✅ DATA GENERATION COMPLETE!")
    print("=" * 70)
    
    print(f"\n📁 Generated files in '{output_dir}/':")
    print(f"   • products.csv              - {len(df_products):,} products")
    print(f"   • products.json             - Same in JSON format")
    print(f"   • customers.csv             - {len(df_customers):,} customers")
    print(f"   • orders.csv                - {len(df_orders):,} orders")
    print(f"   • order_items.csv           - {len(df_order_items):,} items")
    print(f"   • support_conversations.csv - {len(df_conversations):,} conversations")
    print(f"   • knowledge_base.csv        - {len(df_kb)} KB articles")
    print(f"   • knowledge_base.json       - Same in JSON format")
    print(f"   • product_embeddings.pkl    - {len(embeddings):,} embeddings")
    
    print("\n📊 Dataset Statistics:")
    print(f"   Products:        {len(df_products):,}")
    print(f"   Customers:       {len(df_customers):,}")
    print(f"   Orders:          {len(df_orders):,}")
    print(f"   Order Items:     {len(df_order_items):,}")
    print(f"   Conversations:   {len(df_conversations):,}")
    print(f"   KB Articles:     {len(df_kb)}")
    print(f"   Total Revenue:   ${total_revenue:,.2f}")
    print(f"   Avg Order Value: ${avg_order_value:.2f}")
    
    print("\n🎓 Usage in Course Modules:")
    print("   Modules 1-9  (MLOps):     Use products, customers, orders for ML models")
    print("   Modules 10-11 (LLMOps):   Use products.json + knowledge_base.json for RAG")
    print("   Modules 12-14 (Agents):   Use support_conversations + all data for agents")
    
    print("\n💡 Next Steps:")
    print("   1. Load data into services (run setup script)")
    print("   2. Import embeddings into vector DB")
    print("   3. Test services with sample queries")
    print("   4. Start Module 1!")
    
    return {
        'products': df_products,
        'customers': df_customers,
        'orders': df_orders,
        'order_items': df_order_items,
        'conversations': df_conversations,
        'knowledge_base': df_kb,
        'embeddings': embeddings
    }


# ============================================================================
# CLI INTERFACE
# ============================================================================

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Generate synthetic e-commerce data for MLOps course"
    )
    parser.add_argument(
        "--products",
        type=int,
        default=500,
        help="Number of products to generate (default: 500)"
    )
    parser.add_argument(
        "--customers",
        type=int,
        default=5000,
        help="Number of customers to generate (default: 5000)"
    )
    parser.add_argument(
        "--orders",
        type=int,
        default=10000,
        help="Number of orders to generate (default: 10000)"
    )
    parser.add_argument(
        "--conversations",
        type=int,
        default=2000,
        help="Number of support conversations (default: 2000)"
    )
    parser.add_argument(
        "--output",
        type=str,
        default="data",
        help="Output directory (default: data/)"
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for reproducibility (default: 42)"
    )
    
    args = parser.parse_args()
    
    # Set random seed
    random.seed(args.seed)
    np.random.seed(args.seed)
    Faker.seed(args.seed)
    
    # Generate data
    generate_all_data(
        n_products=args.products,
        n_customers=args.customers,
        n_orders=args.orders,
        n_conversations=args.conversations,
        output_dir=args.output
    )

