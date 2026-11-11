#!/usr/bin/env python3
"""
Verify Module 01 setup is complete
"""

import requests
import sys

def check_service(name, url):
    """Check if service is responding"""
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            print(f"✅ {name}: OK")
            return True
        else:
            print(f"❌ {name}: HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ {name}: {str(e)}")
        return False

def main():
    services = {
        "ML Service": "http://localhost:8001/health",
        "RAG Service": "http://localhost:8002/health",
        "Agent Service": "http://localhost:8003/health",
        "MLflow": "http://localhost:5000",
        "Grafana": "http://localhost:3000",
        "Prometheus": "http://localhost:9090",
    }
    
    print("Verifying Module 01 Setup...")
    print("=" * 50)
    
    results = []
    for name, url in services.items():
        results.append(check_service(name, url))
    
    print("=" * 50)
    
    if all(results):
        print("✅ All services are running!")
        print("\nYou're ready for Module 01!")
        sys.exit(0)
    else:
        print("❌ Some services are not running")
        print("\nSee TROUBLESHOOTING.md")
        sys.exit(1)

if __name__ == "__main__":
    main()