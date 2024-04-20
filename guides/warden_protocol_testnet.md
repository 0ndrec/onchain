### Warden Protocol

Warden Protocol представляет собой модульную инфраструктуру блокчейна первого уровня, разработанную для приложений, работающих в различных блокчейнах (OApps). Эта платформа предлагает значительные преимущества в разработке и безопасности блокчейн-приложений:

1. **Модульная безопасность**: Протокол позволяет разработчикам использовать различные модели безопасности для одних и тех же приложений, минимизируя фрагментацию безопасности и позволяя пользователям выбирать уровень доверия к приложениям.
2. **Омничейн интероперабельность**: Warden Protocol обеспечивает беспрецедентную межцепочечную совместимость, позволяя приложениям взаимодействовать через разные блокчейны без изоляции и фрагментации экосистем.
3. **Абстракция цепочек**: Платформа позволяет приложениям взаимодействовать с любыми другими блокчейнами, что открывает новые возможности для создания и использования приложений.
4. **Универсальные пространства**: Пользователи могут взаимодействовать с различными блокчейнами с помощью уникальных идентификаторов, что упрощает многоцепочечные взаимодействия и повышает удобство использования.

### Пошаговое руководство по запуску валидатора Warden Protocol

#### Настройка сервера
1. **Обновление системы и установка зависимостей**:
   ```
   sudo apt update
   sudo apt upgrade -y
   sudo apt install -y curl git jq lz4 build-essential
   ```

2. **Установка Go**:
   ```
   sudo rm -rf /usr/local/go
   curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
   echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
   source .bash_profile
   ```

#### Установка узла
1. **Клонирование репозитория и настройка**:
   ```
   cd $HOME && rm -rf wardenprotocol
   git clone https://github.com/warden-protocol/wardenprotocol
   cd wardenprotocol
   git checkout v0.3.0
   make install-wardend
   ```

2. **Конфигурация клиента и инициализация узла**:
   ```
   wardend config set client chain-id buenavista-1
   wardend config set client keyring-backend test
   wardend config set client node tcp://localhost:26657
   wardend init "Your Node Name" --chain-id buenavista-1
   ```

3. **Настройка файлов начальной загрузки и конфигурации**:
   ```
   curl -L https://snapshots-testnet.nodejumper.io/wardenprotocol-testnet/genesis.json > $HOME/.warden/config/genesis.json
   curl -L https://snapshots-testnet.nodejumper.io/wardenprotocol-testnet/addrbook.json > $HOME/.warden/config/addrbook.json
   ```

   Настройка сидов и минимальной цены газа:
   ```
   sed -i -e 's|^seeds *=.*|seeds = "ddb4d92ab6eba8363bab2f3a0d7fa7a970ae437f@sentry-1.buenavista.wardenprotocol.org:26656,c717995fd56dcf0056ed835e489788af4ffd8fe8@sentry-2.buenavista.wardenprotocol.org:26656,e1c61de5d437f35a715ac94b88ec62c482edc166@sentry-3.buenavista.wardenprotocol.org:26656"|' $HOME/.warden/config/config.toml
   sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.01uward"|' $HOME/.warden/config/app.toml
   ```

4. **Запуск и мониторинг узла**:
   ```
   sudo systemctl start wardend.service
   sudo journalctl -u wardend.service -f --no-hostname -o cat
   ```
