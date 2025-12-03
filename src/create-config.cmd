@echo off
setlocal enabledelayedexpansion

:: Create config folder
if not exist "config" mkdir ..\config
if not exist "reports" mkdir ..\reports
if not exist "logs" mkdir ..\logs

:: Create ssh-tokens.txt
> ..\config\ssh-tokens.txt (
echo # SSH Configuration Files
echo sshd_config
echo ssh_config
echo config
echo authorized_keys
echo known_hosts
echo ssh_known_hosts
echo(
echo # SSH Tools and Utilities 
echo ssh
echo sshd
echo ssh-keygen
echo ssh-keyscan
echo ssh-agent
echo sshpass
echo openssh
echo sftp
echo scp
echo putty
echo puttygen
echo pageant
echo pscp
echo plink
echo(
echo # SSH Clients
echo mobaxterm
echo termius
echo securecrt
echo cygwin
echo tunnelblick
echo winscp
echo(
echo # Tunneling , Proxy ,and  Remote Access
echo tunnel
echo forwarding
echo proxyjump
echo jumpbox
echo bastion
echo remote
echo session
echo terminal
echo(
echo # Secrets and Credentials
echo vault
echo secrets
echo cred
echo credentials
echo encrypted
echo enc
echo secure
echo gnupg
echo gpg
echo pgp
echo(
echo # Key Formats and Identifiers
echo id_ed25519
echo id_ecdsa
echo id_rsa
echo id_dsa
echo id_xmss
echo id_gost
echo id_ntru
echo private_key
echo public_key
echo identity
echo ssh_key
echo key
echo priv
echo pub
echo(
echo # Asymmetric Algorithms
echo rsa
echo dsa
echo ecdsa
echo ed25519
echo x25519
echo xmss
echo gost
echo ntru
echo(
echo # Symmetric Algorithms
echo aes
echo chacha
echo chacha20
echo xchacha20
echo serpent
echo twofish
echo blowfish
echo(
echo # Hashing Algorithms
echo sha1
echo sha256
echo sha512
echo sha3
echo keccak
echo blake2
echo blake3
echo md5
echo(
echo # Key Derivation and Password Hashing
echo argon2
echo pbkdf2
echo bcrypt
echo scrypt
echo hkdf
echo(
echo # Post-Quantum Cryptography 
echo kyber
echo dilithium
echo falcon
echo sphincs
echo sphincs+
echo ntruprime
echo bike
echo frodo
echo newhope
echo(
echo # Certificates and Trust
echo x509
echo crt
echo cer
echo der
echo p12
echo pfx
echo jks
echo jceks
echo pkcs7
echo p7b
echo p7c
echo cert
echo pki
echo trust
echo auth
echo ssl
echo tls
)

:: Create crypto-extensions.txt
> ..\config\crypto-extensions.txt (
echo # Key and Public Key Formats
echo .key
echo .pub
echo .pem
echo .ppk
echo(
echo # Encrypted Key Formats
echo .gpg
echo .asc
echo .kbx
echo(
echo # Certificate and PKI Formats
echo .crt
echo .cer
echo .der
echo .p12
echo .pfx
echo .p7b
echo .p7c
echo .jks
echo .jceks
echo .pkcs
echo(
echo # Hash and Signature Files
echo .sha
echo .sha256
echo .sha512
echo .blake2
echo .blake3
echo(
echo # Password Hashing / KDF Artifacts
echo .argon2
echo .scrypt
echo .bcrypt
)

:: Create win-batch-extensions.txt
> ..\config\win-batch-extensions.txt (
echo # Windows Batch and Script Formats
echo .bat
echo .cmd
echo .ps1
echo .vbs
echo .js
echo .wsf
echo(
echo # Executables and Installers
echo .exe
echo .msi
echo .com
echo(
echo # Registry and Shortcuts
echo .reg
echo .lnk
)

:: Create library-extensions.txt
> ..\config\library-extensions.txt (
echo # Dynamic and Static Libraries
echo .dll
echo .lib
echo .ocx
echo .sys
echo .drv
echo .cpl
echo .ax
echo .bpl
echo(
echo # Type and Object Libraries
echo .tlb
echo .olb
echo .mui
echo .res
echo .obj
echo .pdb
)

:: Create file-extensions.txt
> ..\config\file-extensions.txt (
echo # Web and Frontend
echo .html
echo .htm
echo .css
echo .scss
echo .sass
echo .less
echo .jsp
echo .jsf
echo(
echo # Source Code and Scripts
echo .c
echo .cpp
echo .cc
echo .cxx
echo .h
echo .hpp
echo .hxx
echo .cs
echo .java
echo .js
echo .jsx
echo .ts
echo .tsx
echo .py
echo .pyi
echo .rb
echo .go
echo .rs
echo .swift
echo .m
echo .mm
echo .php
echo .pl
echo .pm
echo .lua
echo .sh
echo .bash
echo .zsh
echo .bat
echo .cmd
echo .ps1
echo .vbs
echo .groovy
echo .scala
echo .kt
echo .kts
echo .dart
echo .erl
echo .ex
echo .exs
echo .clj
echo .cljs
echo .lisp
echo .scm
echo .ml
echo .fs
echo .fsx
echo .nim
echo .ada
echo .d
echo .asm
echo .s
echo .vb
echo .bas
echo .f90
echo .for
echo .pas
echo .prolog
echo .awk
echo .rexx
echo(
echo # Data Science and Scientific Computing
echo .r
echo .sas
echo .mat
echo .nb
echo .ipynb
echo .mc
echo .csv
echo .tsv
echo .sql
echo(
echo # Compiled or Intermediate Files
echo .class
echo .jar
echo .war
echo .ear
echo .dll
echo .so
echo .a
echo .lib
echo .o
echo .obj
echo .exe
echo .out
echo .pyc
echo .pyo
echo .beam
echo .hi
echo .mod
echo .dcu
echo .fasl
echo .rbc
echo .rbo
echo .pdb
echo .apk
echo .app
echo .wasm
echo .dex
echo .xex
echo .bin
echo .sav
echo .dat
echo .map
echo .sym
echo .idb
echo .bpl
echo .dylib
echo(
echo # Build and Config Artifacts
echo .json
echo .yaml
echo .yml
echo .toml
echo .ini
echo .cfg
echo .config
echo .lock
echo .make
echo .mk
echo .gradle
echo .cmake
echo .sln
echo .vcxproj
echo .csproj
echo .xcodeproj
echo .project
echo .classpath
echo .manifest
echo(
echo # Documentation and Metadata
echo .txt
echo .md
echo .pdf
echo .doc
echo .docx
echo .chm
echo .nfo
echo .rtf
echo .license
echo .licence
echo .rst
echo .adoc
echo .tex
echo .log
echo .readme
echo .xml
echo(
echo # Email and Messaging
echo .eml
echo .msg
echo .pst
echo .ost
echo .mbox
echo .vcf
echo .ics
echo(
echo # Office Documents and Macros
echo .xls
echo .xlsx
echo .ppt
echo .pptx
echo .dot
echo .dotm
echo .xlt
echo .xltm
echo .xla
echo .xlam
echo .pptm
echo .potm
echo .ppam
echo .pub
echo .one
echo .odt
echo .ods
echo .odp
echo .odf
echo(
echo # Batch and Automation 
echo .bat
echo .cmd
echo .sh
echo .bash
echo .zsh
echo .ps1
echo .vbs
echo .wsf
echo .ksh
echo .csh
echo .tcl
echo .expect
)

echo Config files created in the "..\config" folder.
Pause
