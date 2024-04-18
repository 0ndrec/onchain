
# Настройка безопасности сервера на Ubuntu

## Шаг 1: Обновление системы

Обновите систему и установленные пакеты:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
```

## Шаг 2: Настройка Firewall (UFW)

Установка и настройка Uncomplicated Firewall (UFW):

```bash
sudo apt install ufw -y
sudo ufw allow ssh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo ufw status
```

## Шаг 3: Создание нового пользователя

Создание пользователя и добавление его в группу sudo:

```bash
sudo adduser <username>
sudo usermod -aG sudo <username>
```


## Шаг 4: Настройка аутентификации по ключам SSH

Генерация ключей и их копирование на сервер:

```powershell
ssh-keygen
ssh <username>@<server-ip> "umask 077; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys || exit 1" < \\path_to_where_the_file_was_generated_from_ssh_key_gen\id_rsa.pub
```
С Linux машины:

```bash
ssh-keygen
ssh-copy-id <username>@<server-ip>
```

## Шаг 5: Установка и настройка fail2ban

Установка и активация fail2ban:

```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## Шаг 6: Настройка SSH

Измените конфигурацию SSH для увеличения безопасности:

```bash
sudo nano /etc/ssh/sshd_config
```

- `PermitRootLogin no` — запрет входа для root.
- `PasswordAuthentication no` — только аутентификация по ключам.

Перезапустите SSH:

```bash
sudo systemctl restart sshd
```

## Шаг 7: Планирование резервного копирования

Настройте резервное копирование с использованием rsync или других инструментов.

