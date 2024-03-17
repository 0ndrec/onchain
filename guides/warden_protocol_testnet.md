
# Руководство по установке и созданию валидатора на Alfama Testnet

## Часть первая: Установка GoLang и загрузка репозитория

### Установка инструментов сборки
1. Установите Go, следуя инструкциям на официальном сайте [https://golang.org/doc/install](https://golang.org/doc/install).

### Скачивание и настройка бинарного файла warden
1. Клонируйте репозиторий Warden Protocol версии v0.1.0:
   ```
   git clone --depth 1 --branch v0.1.0 https://github.com/warden-protocol/wardenprotocol/
   ```
2. Перейдите в директорию `wardenprotocol/warden/cmd/wardend` и соберите бинарный файл:
   ```
   go build
   ```
3. Переместите `wardend` в `/usr/local/bin/`:
   ```
   sudo mv wardend /usr/local/bin/
   ```
4. Инициализируйте каталог данных ноды:
   ```
   wardend init <custom_moniker>
   ```

### Подготовка файла genesis
1. Перейдите в каталог конфигурации `.warden/config`.
2. Удалите существующий файл genesis.json:
   ```
   rm genesis.json
   ```
3. Скачайте новый файл genesis:
   ```
   wget https://raw.githubusercontent.com/warden-protocol/networks/main/testnet-alfama/genesis.json
   ```
4. Установите минимальную цену газа и укажите постоянные пиры:
   [Инструкции по настройке].

## Часть вторая: Создание валидатора

### Создание или восстановление локального кошелька
1. Создайте новую пару ключей или восстановите существующий кошелек для вашего валидатора:
   ```
   wardend keys add <key-name>
   ```
   или для восстановления:
   ```
   wardend keys add <key-name> --recover
   ```
2. Просмотрите ваш публичный адрес:
   ```
   wardend keys show <key-name> -a
   ```

### Получение тестовых токенов WARD
1. Получите тестовые токены, чтобы финансировать ваш адрес:
   ```
   curl --json '{"address": "<your-address>"}' https://faucet.alfama.wardenprotocol.org
   ```
2. Проверьте баланс:
   ```
   wardend query bank balances <key-name>
   ```

### Создание нового валидатора
1. Получите публичный ключ вашего валидатора:
   ```
   wardend comet show-validator
   ```
2. Создайте файл `validator.json` с необходимыми данными и параметрами вашего валидатора.
3. Отправьте транзакцию для создания валидатора:
   ```
   wardend tx staking create-validator validator.json --from=<key-name> --chain-id=alfama --fees=500uward
   ```

### Резервное копирование критически важных файлов
1. Создайте зашифрованную резервную копию файлов `priv_validator_key.json` и `node_key.json`.

### Проверка активного статуса валидатора
1. Проверьте, входит ли ваш валидатор в активный набор:
   ```
   wardend query comet-validator-set | grep "$(wardend comet show-address)"
   ```

Важно следить за актуальностью информации на официальном сайте и в документации Warden Protocol, так как параметры и процедуры могут изменяться.
