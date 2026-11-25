# SS-PRATICO

Material de estudo para o teste prático de **Segurança de Sistemas** (Engenharia Informática).
Tudo funciona **offline** — abre os `.html` no browser.

## Conteúdo

| Ficheiro | O que é |
|---|---|
| [`dicionario-ss.html`](dicionario-ss.html) | Dicionário de opções por ferramenta (nmap · ssh · iptables · squid · cifra · gpg · linux): cada opção com o molde da linha, um exemplo e pesquisa por flag exata. Inclui montadores de linha para nmap e iptables, os ficheiros prontos e as respostas ao teste de treino. |
| [`guia-ss.html`](guia-ss.html) | Guia completo: matéria por módulo, documentação pesquisável, exercícios, testes modelo 1, 2 e 3 (o 3 é simples, com um pouco de tudo e o template oficial), gerador de iptables e scripts. |
| [`iptables_template.sh`](iptables_template.sh) | O template do professor (é este que se altera no teste). |
| [`scripts/`](scripts/) | Scripts e exemplos de configuração prontos. |

## scripts/

- **iptables** — `firewall-off.sh`, `firewall-stateful.sh`, `gateway-nat.sh`, `proxy-transparente.sh`, `redirect-2022.sh`, `facebook-block.sh`, `limit-ping.sh`, `limit-ping-inverso.sh`
- **Squid** — `squid.conf.exemplo`
- **SSH** — `sshd_config.exemplo`, `jail.local` (fail2ban)
- **Cifra/hash** — `brute-hash.py` (descobre os dígitos que dão um hash SHA-256)

Correr um script: `chmod +x nome.sh` e depois `sudo ./nome.sh`.

> Módulos M1–M7: Linux/serviços, nmap, SSH, iptables, Squid, cifra simétrica/hash/esteganografia, GnuPG/EasyRSA.
