#!/usr/bin/env python3
# Força bruta: descobre xxxx (0000-9999) tal que SHA256("%&xxxx") == alvo
# Correr:  python3 brute-hash.py
# Outro algoritmo: trocar hashlib.sha256 por hashlib.md5 / sha1 / sha512
import hashlib

alvo = "5c768b72dd12f977360d0124c0adf74c44c809b4aa08de07a3acffbc576b15f4"
prefixo = "%&"

for n in range(10000):
    candidato = f"{prefixo}{n:04d}"          # 7 -> "0007"
    if hashlib.sha256(candidato.encode()).hexdigest() == alvo:
        print("Encontrei:", candidato)
        break
else:
    print("Não encontrado")
