#!/usr/bin/env python3
"""
Smoke Test - Web-Bot
Valida endpoints principais do backend
"""

import requests
import json
import sys
import time
from typing import Dict, List, Tuple

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

class SmokeTest:
    def __init__(self, base_url: str = "http://localhost:3001"):
        self.base_url = base_url
        self.results: List[Dict] = []
        self.token: str = None
        
    def log(self, message: str, color: str = Colors.BLUE):
        timestamp = time.strftime("%H:%M:%S")
        print(f"[{timestamp}] {color}{message}{Colors.END}")
        
    def test_endpoint(
        self, 
        method: str, 
        endpoint: str, 
        expected_status: int = 200, 
        data: Dict = None,
        headers: Dict = None
    ) -> Tuple[bool, Dict]:
        """Testa um endpoint específico"""
        url = f"{self.base_url}{endpoint}"
        
        try:
            start_time = time.time()
            
            if method.upper() == "GET":
                response = requests.get(url, headers=headers, timeout=10)
            elif method.upper() == "POST":
                response = requests.post(url, json=data, headers=headers, timeout=10)
            else:
                return False, {"error": f"Método {method} não suportado"}
            
            elapsed = time.time() - start_time
            success = response.status_code == expected_status
            
            result = {
                "method": method,
                "endpoint": endpoint,
                "status_code": response.status_code,
                "expected_status": expected_status,
                "success": success,
                "response_time": elapsed
            }
            
            try:
                result["response_data"] = response.json()
            except:
                result["response_data"] = response.text[:100]
            
            self.results.append(result)
            
            if success:
                self.log(f"✅ {method} {endpoint} - {response.status_code} ({elapsed:.3f}s)", Colors.GREEN)
            else:
                self.log(f"❌ {method} {endpoint} - {response.status_code} (esperado: {expected_status})", Colors.RED)
            
            return success, result
            
        except requests.exceptions.ConnectionError:
            self.log(f"❌ Conexão recusada: {url}", Colors.RED)
            return False, {"error": "Connection refused"}
        except requests.exceptions.Timeout:
            self.log(f"❌ Timeout: {url}", Colors.RED)
            return False, {"error": "Timeout"}
        except Exception as e:
            self.log(f"❌ Erro: {str(e)}", Colors.RED)
            return False, {"error": str(e)}
    
    def test_health(self) -> bool:
        """Testa health check"""
        self.log("🔍 Testando health check...", Colors.BLUE)
        return self.test_endpoint("GET", "/health")[0]
    
    def test_api_test(self) -> bool:
        """Testa endpoint de teste"""
        self.log("🔍 Testando API test endpoint...", Colors.BLUE)
        return self.test_endpoint("GET", "/api/test")[0]
    
    def test_gateways(self) -> bool:
        """Testa listagem de gateways"""
        self.log("🔍 Testando gateways...", Colors.BLUE)
        return self.test_endpoint("GET", "/api/gateways")[0]
    
    def test_login(self) -> bool:
        """Testa autenticação"""
        self.log("🔍 Testando login...", Colors.BLUE)
        success, result = self.test_endpoint(
            "POST", 
            "/api/auth/login",
            200,
            {"username": "admin", "password": "admin123"}
        )
        
        if success and "response_data" in result:
            self.token = result["response_data"].get("token")
            if self.token:
                self.log(f"✅ Token obtido: {self.token[:20]}...", Colors.GREEN)
        
        return success
    
    def test_verify_token(self) -> bool:
        """Testa verificação de token"""
        if not self.token:
            self.log("⚠️  Pulando teste de token (login falhou)", Colors.YELLOW)
            return False
        
        self.log("🔍 Testando verificação de token...", Colors.BLUE)
        headers = {"Authorization": f"Bearer {self.token}"}
        return self.test_endpoint("GET", "/api/auth/verify", 200, headers=headers)[0]
    
    def run_all(self) -> Dict:
        """Executa todos os testes"""
        self.log("=" * 60, Colors.BLUE)
        self.log("SMOKE TEST - WEB-BOT BACKEND", Colors.BLUE)
        self.log("=" * 60, Colors.BLUE)
        self.log(f"Base URL: {self.base_url}", Colors.BLUE)
        self.log("", Colors.BLUE)
        
        tests = [
            ("Health Check", self.test_health),
            ("API Test", self.test_api_test),
            ("Gateways", self.test_gateways),
            ("Login", self.test_login),
            ("Verify Token", self.test_verify_token)
        ]
        
        passed = 0
        total = len(tests)
        
        for name, test_func in tests:
            try:
                if test_func():
                    passed += 1
            except Exception as e:
                self.log(f"❌ Erro no teste {name}: {str(e)}", Colors.RED)
        
        self.log("", Colors.BLUE)
        self.log("=" * 60, Colors.BLUE)
        self.log("RESUMO DOS TESTES", Colors.BLUE)
        self.log("=" * 60, Colors.BLUE)
        self.log(f"Total: {total}", Colors.BLUE)
        self.log(f"Passou: {passed}", Colors.GREEN)
        self.log(f"Falhou: {total - passed}", Colors.RED if total - passed > 0 else Colors.GREEN)
        self.log(f"Taxa de sucesso: {(passed/total)*100:.1f}%", Colors.GREEN if passed == total else Colors.YELLOW)
        self.log("=" * 60, Colors.BLUE)
        
        return {
            "total": total,
            "passed": passed,
            "failed": total - passed,
            "success_rate": (passed / total) * 100,
            "results": self.results
        }

def main():
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:3001"
    
    tester = SmokeTest(base_url)
    summary = tester.run_all()
    
    # Exit code baseado no resultado
    if summary["success_rate"] >= 80:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()



