# E2E тести (Puppeteer)

Мови: [Polski (default)](README.md) · [English](README.en.md) · Українська

---

Автоматизовані end-to-end тести для застосунку AKAdemy з використанням Puppeteer.

## Вимоги

- Node.js + Yarn
- Puppeteer (встановлюється автоматично через `yarn install`)
- Запущений застосунок на `localhost:3000`
- Тестові дані в базі (`rake db:seed`)

## Налаштування

### Змінні середовища

| Змінна | Опис | За замовчуванням |
|--------|------|------------------|
| `E2E_BASE_URL` | URL застосунку | `http://localhost:3000` |
| `E2E_HEADLESS` | Режим headless | `true` |

### Тестові користувачі

Тести використовують користувачів з сіду "Włatcy Móch":

- **Суперадмін**: `sladkowski@webgate.pro` / `devpass!`
- **Директор**: `bartus@wlatcy.edu.pl` / `devpass!`
- **Вчитель**: `teachertest@gmail.com` / `devpass!`
- **Учень**: `+48123234345` / PIN: `0000`

## Запуск тестів

```bash
# Запустіть Rails сервер (в окремому терміналі)
bin/dev

# Запустити всі тести (headless)
rake test

# Запустити з видимим браузером
rake test:gui

# Запустити окремий тест (headless)
rake test[superadmin-menu]

# Запустити окремий тест з GUI
rake test[superadmin-menu,gui]
```

## Доступні тести

| Тест | Опис |
|------|------|
| `superadmin-menu` | Навігація меню панелі суперадміна |
| `superadmin-users` | Керування користувачами (фільтрація, редагування) |
| `superadmin-content` | Керування контентом (предмети, модулі) |
| `principal-dashboard` | Меню панелі директора |
| `principal-management` | Керування класами, вчителями, учнями |
| `teacher-dashboard` | Меню панелі вчителя |
| `teacher-dashboard-full` | Повний тест функцій вчителя |
| `student-dashboard` | Меню панелі учня |
| `student-dashboard-full` | Повний тест функцій учня |
| `theme-switcher` | Перемикання теми світла/темна |
| `dashboard-switcher` | Перемикання вчитель↔директор |
| `subjects-dragdrop` | Drag & drop предметів |

## Структура файлів

```
e2e/
├── config.js           # Конфігурація (URL, таймаути, користувачі)
├── run-all.js          # Запуск всіх тестів
├── README.md           # Документація (польська)
├── README.en.md        # Документація (англійська)
├── README.ua.md        # Цей файл (українська)
├── helpers/
│   ├── browser.js      # Хелпер Puppeteer (навігація, кліки, форми)
│   └── auth.js         # Хелпер авторизації (superadmin, teacher, student, principal)
├── tests/
│   ├── superadmin-menu.test.js
│   ├── superadmin-users.test.js
│   ├── superadmin-content.test.js
│   ├── principal-dashboard.test.js
│   ├── principal-management.test.js
│   ├── teacher-dashboard.test.js
│   ├── teacher-dashboard-full.test.js
│   ├── student-dashboard.test.js
│   ├── student-dashboard-full.test.js
│   ├── theme-switcher.test.js
│   ├── dashboard-switcher.test.js
│   └── subjects-dragdrop.test.js
└── screenshots/        # Скріншоти (генеруються при помилках)
```

## Написання нових тестів

```javascript
// e2e/tests/my-test.test.js

const browser = require('../helpers/browser');
const auth = require('../helpers/auth');

async function runTest() {
  let testPassed = false;
  
  console.log('🚀 Запуск мого тесту...\n');
  
  try {
    await browser.launch();
    
    // Авторизація
    await auth.loginAsSuperadmin();
    console.log('   ✓ Авторизовано');
    
    // Навігація
    await browser.goto('/admin/schools');
    console.log('   ✓ Перехід до шкіл');
    
    // Взаємодія
    await browser.click('.btn-new');
    await browser.type('#school_name', 'Тестова школа');
    
    // Перевірка
    const exists = await browser.exists('.success-message', 2000);
    if (exists) {
      console.log('   ✓ Повідомлення про успіх показано');
      testPassed = true;
    }
    
  } catch (error) {
    console.error('❌ ПОМИЛКА ТЕСТУ:', error.message);
    await browser.screenshot('my-test-error');
    
  } finally {
    await browser.close();
  }
  
  console.log(testPassed ? '\n✅ ТЕСТ ПРОЙДЕНО\n' : '\n❌ ТЕСТ НЕ ПРОЙДЕНО\n');
  return testPassed;
}

runTest()
  .then(passed => process.exit(passed ? 0 : 1))
  .catch(error => {
    console.error('Критична помилка:', error);
    process.exit(1);
  });
```

## API хелперів

### browser.js

```javascript
// Навігація
await browser.goto('/path');           // Перейти за шляхом
await browser.waitFor('selector');     // Чекати на елемент
await browser.waitForNavigation();     // Чекати на навігацію

// Взаємодії
await browser.click('selector');       // Клікнути елемент
await browser.type('selector', 'text'); // Ввести текст (з анімацією)
await browser.fastType('selector', 'text'); // Ввести текст (миттєво)

// Перевірки
await browser.exists('selector', timeout); // Чи існує елемент?
await browser.getText('selector');     // Отримати текст елемента
browser.url();                         // Поточний URL

// Утиліти
await browser.sleep(ms);               // Пауза
await browser.screenshot('name');      // Зробити скріншот
browser.getPage();                     // Доступ до Puppeteer page
```

### auth.js

```javascript
await auth.loginAsSuperadmin();  // Увійти як суперадмін
await auth.loginAsTeacher();     // Увійти як вчитель
await auth.loginAsPrincipal();   // Увійти як директор
await auth.loginAsStudent();     // Увійти як учень (телефон + PIN)
```

## Режим GUI - візуальний курсор

В режимі `rake test:gui` відображається візуальний курсор (золота стрілка), який:
- Плавно переміщується до елементів перед кліком
- Показує ефект кліку (зменшення)
- Залишається видимим між діями

Параметри швидкості відрізняються для режиму headless (швидкий) та GUI (повільніший, більш наочний).

## Вирішення проблем

### Тест не проходить тільки в режимі headless

Додайте більше затримок:
```javascript
await browser.sleep(browser.getSpeed().mediumPause);
```

### Елемент не знайдено

1. Перевірте CSS селектор
2. Додайте `await browser.waitFor('selector')` перед дією
3. Використайте `await browser.screenshot('debug')` для налагодження

### Таймаут завантаження сторінки

Збільште таймаут в `config.js`:
```javascript
timeouts: {
  implicit: 20000,  // 20 секунд
  pageLoad: 60000,  // 60 секунд
}
```

### Проблеми з авторизацією

Перевірте:
1. Застосунок запущено (`bin/dev`)
2. Тестові дані є в базі (`rake db:seed`)
3. Користувачі в `config.js` правильні

