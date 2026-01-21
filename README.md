# SINS
# Использование

**!!! КРАЙНЕ РЕКОМЕНДУЕТСЯ скачать архив из вкладки Release !!!**

1. Скачать из релизов сборку с модулями
2. Перенести на тестовый стенд и выдать бит запуска:

   ```chmod +x ./singleScript.sh ```

3. Запустить:
   
   ```sudo ./singleScript.sh```

## Анализ результатов



### Анализ before/after
Использовать любое ПО для сравнения 2 файлов, к примеру [WinMerge](https://winmerge.org/?lang=ru)


# Как добавить свой модуль:

### Vibe Coding

1. Скачать Vibe-Coding.txt

2. Загрузить  файл или текст из файла в LLM и поставить задачу.

### Обычный метод

Условия для работы

- папка модуля должна находиться в папке modules
- модуль должен иметь файл sinsmod.sh, находящийся в корне каталога модуля

Также нужно учитывать, что существуют глобальные:

- переменные: METRICS_DIR, MENU_ITEMS, MODULES_DIR.
- функции: main, on_init, on_update_ask, on_menu, on_pre_holiday, on_holiday, on_post_holiday, on_pre_before, on_before, on_post_before, on_pre_live, on_live, on_post_live, on_pre_after, on_after, on_post_after, pause, create_metric_folder, run_modules_func

Остальную информацию можно получить просмотрев файл: modules\onBeforeLiveAfterExample\sinsmod.sh
