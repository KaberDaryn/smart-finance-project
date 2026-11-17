/* ============================================================
   Smart Finance — browser application logic.
   Vanilla ES2020, no frameworks, no build step.
   Served statically by the Python backend; talks to its real API.
   ============================================================ */
'use strict';

/* ---------- 1. Constants ---------- */
const API = '';
let PAGE_SIZE = 10;
const PAGES = { overview: 'Overview', transactions: 'Transactions', insights: 'Insights', planning: 'Planning' };
const EXPENSE_CATEGORIES = ['Groceries', 'Transport', 'Housing', 'Entertainment', 'Health', 'Cafe', 'Clothing', 'Other'];
const INCOME_CATEGORIES = ['Salary', 'Freelance', 'Bonus', 'Investment', 'Gift', 'Other'];
const RECEIPT_CURRENCIES = ['KZT', 'RUB', 'USD', 'EUR'];
const CURRENCIES = {
  KZT: '₸', USD: '$', EUR: '€', GBP: '£', RUB: '₽', CNY: '¥', JPY: '¥',
};
const CAT_META = {
  Groceries: { icon: 'i-cart', color: '#d7dde6' },
  Transport: { icon: 'i-car', color: '#b9c2cf' },
  Housing: { icon: 'i-home', color: '#9aa5b5' },
  Entertainment: { icon: 'i-film', color: '#7d8899' },
  Health: { icon: 'i-heart', color: '#646e7e' },
  Cafe: { icon: 'i-coffee', color: '#4f5866' },
  Clothing: { icon: 'i-shirt', color: '#3d4553' },
  Other: { icon: 'i-tag', color: '#565f6e' },
  Salary: { icon: 'i-briefcase', color: '#c3cbd6' },
  Freelance: { icon: 'i-briefcase', color: '#c3cbd6' },
  Bonus: { icon: 'i-gift', color: '#c3cbd6' },
  Investment: { icon: 'i-coins', color: '#c3cbd6' },
  Gift: { icon: 'i-gift', color: '#646e7e' },
};
const CAT_I18N = {
  ru: {
    Groceries: 'Продукты', Transport: 'Транспорт', Housing: 'Жильё', Entertainment: 'Развлечения',
    Health: 'Здоровье', Cafe: 'Кафе', Clothing: 'Одежда', Other: 'Другое',
    Salary: 'Зарплата', Freelance: 'Фриланс', Bonus: 'Премия', Investment: 'Инвестиции', Gift: 'Подарок',
  },
  kz: {
    Groceries: 'Азық-түлік', Transport: 'Көлік', Housing: 'Тұрғын үй', Entertainment: 'Ойын-сауық',
    Health: 'Денсаулық', Cafe: 'Кафе', Clothing: 'Киім', Other: 'Басқа',
    Salary: 'Жалақы', Freelance: 'Фриланс', Bonus: 'Бонус', Investment: 'Инвестиция', Gift: 'Сыйлық',
  },
};

const FALLBACK_ANALYTICS = {
  categories: [], months: [],
  forecast: { status: 'unavailable', message: 'The forecasting module is not connected.' },
  budgets: [], recommendations: [],
};
const REDUCED_MOTION = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

/* ---------- 1b. Languages: KZ / RU / EN ---------- */
const I18N = {
  en: {
    nav_overview: 'Overview', nav_transactions: 'Transactions', nav_insights: 'Insights', nav_planning: 'Planning',
    tab_home: 'Home', tab_history: 'History', tab_stats: 'Stats', tab_plans: 'Plans',
    hdr_snapshot: 'Your financial snapshot',
    greet_morning: 'Good morning', greet_afternoon: 'Good afternoon', greet_evening: 'Good evening',
    greet_sub: "Here's what's happening with your money.",
    btn_scan_receipt: 'Scan receipt', btn_add_tx: 'Add transaction',
    banner_title: 'Scan a receipt',
    banner_text: 'Merchant, date and total read from the photo. Categories you confirm are remembered.',
    banner_btn: 'Scan',
    card_balance: 'Total balance', card_income: 'Income', card_expenses: 'Expenses',
    all_time: 'All time', this_month: 'this month', tx_word: 'transactions', vs_last: 'vs. last month',
    new_activity: 'New activity', no_change: 'No net change',
    sec_cashflow: 'Cash flow', sec_cashflow_sub: 'Income vs. expenses over time',
    legend_income: 'Income', legend_expenses: 'Expenses', net_6: 'Net {net} · {n} months',
    sec_budget: 'Monthly budget', sec_budget_sub: 'Keep your spending on track',
    spent_this_month: 'Spent this month', no_budget_note: 'No budgets yet — set monthly limits to keep spending on track.',
    manage_budgets: 'Manage budgets', spent: 'spent', limit: 'limit', of: 'of', over_by: 'Over budget by {x}',
    sec_recent: 'Recent transactions', sec_recent_sub: 'Your latest financial activity',
    view_all: 'View all', no_tx_short: 'No transactions yet. Add your first income or expense.',
    sec_goals: 'Savings goals', sec_goals_sub: 'Small steps, big plans',
    no_goals_ov: 'No savings goals yet', no_goals_ov_t: 'Set a goal in Planning and watch the progress ring fill up.',
    page_tx: 'Transactions', page_tx_sub: 'All your income and expenses, in one place.',
    import_csv: 'Import CSV', export_csv: 'Export', scan_qr: 'Scan QR',
    tx_income_m: 'Income', tx_expenses_m: 'Expenses', tx_count_card: 'Transactions',
    across: 'Across {n} categories',
    all_tx: 'All transactions', all_tx_sub: 'Review and manage your activity',
    search_ph: 'Search description, category…',
    all_types: 'All types', opt_income: 'Income', opt_expense: 'Expenses',
    all_categories: 'All categories', all_months: 'All months',
    th_tx: 'Transaction', th_category: 'Category', th_date: 'Date', th_type: 'Type', th_amount: 'Amount',
    today: 'Today', yesterday: 'Yesterday',
    showing: 'Showing {a}–{b} of {n} transactions', no_tx_list: 'No transactions',
    nothing_found: 'Nothing matches your filters', try_another: 'Try a different search or reset the filters.',
    no_tx_yet: 'No transactions yet', no_tx_yet_t: 'Add your first income or expense to get started.',
    amounts_note: 'Amounts in KZT (₸)',
    page_ins: 'Spending insights', page_ins_sub: 'A clearer picture of where your money goes.',
    avg_daily: 'Average daily spend', based_on: 'Based on {d} days of {m}',
    top_category: 'Top category', of_all: '{p}% of all expenses', no_exp_rec: 'Record expenses to see it',
    forecast_card: 'Forecast · {m}', mean3: 'Mean of last 3 complete months',
    by_category: 'Expenses by category', total_spent: 'total spent',
    smart_obs: 'Smart observations', smart_obs_sub: 'Generated from your own records',
    monthly_trend: 'Monthly trend', trend_sub: 'Total expenses per month, last 12 months',
    page_pl: 'Planning', page_pl_sub: 'Build better habits one month at a time.',
    budget_used: 'Budget used', no_budget_for: 'No budgets for {m}',
    budget_cats: 'Budget categories', budget_cats_sub: 'Track your monthly limits',
    new_budget: 'Budget', new_goal_btn: 'New savings goal',
    goals_title: 'Savings goals', goals_sub: 'Your progress, at a glance',
    target: 'Target {x}', funded: '{p}% funded', goal_reached: 'Goal reached', to_go: '{x} to go',
    m_add_tx: 'Add transaction', m_amount: 'Amount (KZT)', m_category: 'Category', m_date: 'Date',
    m_desc: 'Description', suggest: 'Suggest category', save_tx: 'Save transaction',
    m_qr_title: 'Scan QR code',
    m_receipt: 'Scan a receipt', m_recognize: 'Recognize receipt',
    m_import: 'Import from CSV',
    toast_saved: 'Transaction saved.', toast_deleted: 'Transaction deleted.',
    toast_refreshed: 'Data refreshed.', toast_name_saved: 'Display name saved.',
    currency_display: 'Display currency', currency_note: 'Symbol only — records stay in KZT',
    donut_total: 'total spent', all_recorded: 'All recorded expenses',
    rows_per_page: 'Rows per page', start_screen: 'Start screen',
    theme_label: 'Theme', theme_light: 'Light', theme_dark: 'Dark', theme_system: 'System',
    hide_amounts: 'Hide amounts at start',
    toast_hidden: 'Amounts hidden.', toast_visible: 'Amounts visible.',
    profile: 'Profile', display_name: 'Display name (this device)', save_name: 'Save name',
    appearance: 'Appearance', about: 'About', sign_out: 'Sign out',
    sec_data: 'Data',
    acc_settings: 'Account & settings',
    hdr_money: 'Your money movement', hdr_insights: 'Understand your habits', hdr_planning: 'Make your money go further',
    of_monthly_limit: '{p}% of monthly limit', across_goals: 'across {n} goals',
    spent_of: '{a} spent of {b}', all_expenses: 'All expenses', add_funds: 'Add funds',
    update_progress: 'Update progress', goal_reached_upd: 'Goal reached · update amount',
    saved_of_pct: 'Saved {a} of {b} ({p}%).', add_amount_kzt: 'Amount to add (KZT)', total_saved_kzt: 'Total saved (KZT)',
    type_income: 'Income', type_expense: 'Expense',
    obs_over_t: '{c} is over budget', obs_over_d: 'You have spent {s} of your {l} limit for {m}. Review it in Planning.',
    obs_top_t: '{c} leads your spending', obs_top_d: 'It accounts for {p}% of recorded expenses — worth a look if you want to trim it.',
    obs_fc_t: 'Expected spend next month', obs_fc_d: 'A transparent baseline forecast of {x} for {m}, based on the mean of the last three complete months.',
    obs_goals_t: 'Keep your goals moving', obs_goals_d: 'You are {x} away from completing your {w}. Small transfers add up.',
    obs_none_t: 'Keep building your financial picture', obs_none_d: 'Record transactions and set budgets to get useful spending insights.',
    disclaimer: 'Observations are generated from your own records and are not financial advice.',
    rec_card: 'Spending observations', warn_exceeded: 'A monthly budget has been exceeded. Review Planning.',
    qr_status: 'Point the camera at a QR code — its contents will be added to the transaction.',
    in_month: 'in {m}', goal_one: 'goal', goals_word: 'goals',
    toast_budget: 'Budget saved.', toast_budget_del: 'Budget deleted.', toast_goal: 'Goal created.',
    toast_goal_upd: 'Goal progress updated.', toast_goal_del: 'Goal deleted.', toast_goal_hit: 'Goal reached — congratulations!',
    toast_qr: 'QR captured — check the details.', toast_rows: 'Rows per page saved.',
    toast_start: 'Start screen saved.', toast_cur: 'Display currency: {c}',
    toast_priv_on: 'Amounts will be hidden on launch.', toast_priv_off: 'Amounts shown on launch.',
    toast_name: 'Display name saved.', toast_imported: 'Imported {n} transactions.',
    toast_import_dup: 'This file was already imported before — nothing duplicated.',
    toast_exported: 'Exported {n} transactions.', toast_session: 'Session expired — please sign in again.',
    toast_signed_out: 'Signed out.', toast_welcome: 'Welcome, {u}!',
    conf_del_tx: 'Delete transaction?', conf_del_tx_d: 'This permanently removes “{n}” from your ledger.',
    conf_del_budget: 'Delete budget?', conf_del_budget_d: 'The {c} limit for {m} will be removed. Your transactions are not affected.',
    conf_del_goal: 'Delete goal?', conf_del_goal_d: '“{n}” will be removed. Savings already recorded stay in your ledger.',
    conf_sign_out: 'Sign out?', conf_sign_out_d: 'Your session token will be revoked on the server. Your data stays safely stored.',
    m_budget_t: 'New budget', m_budget_edit: 'Edit budget', m_budget_cat: 'Category', m_budget_all: 'All expenses (total)',
    m_budget_month: 'Month', m_budget_limit: 'Monthly limit (KZT)', m_budget_save: 'Create budget',
    m_goal_t: 'New savings goal', m_goal_name: 'Goal name', m_goal_target: 'Target amount (KZT)', m_goal_saved: 'Already saved (KZT, optional)',
    m_goal_create: 'Create goal', m_topup_t: 'Add funds', m_topup_edit: 'Update saved',
    m_tx_t: 'Add transaction', m_quick: 'Quick entry', m_expense: '− Expense', m_income_p: '＋ Income',
    m_amount_kzt: 'Amount (KZT)', m_type: 'Type', m_desc_ph: 'e.g. Weekly groceries',
    m_cancel: 'Cancel', m_save_budget: 'Save changes',
    r_consent: 'I agree to send this receipt photo to the configured recognition provider for processing. Use a sample receipt for demos; don\'t upload sensitive personal details.',
    r_drop: 'Drop a receipt photo or browse', r_recognize: 'Recognize receipt',

    lang_title: 'Language · Тіл · Язык',
    qr_fallback_browser: 'QR scanning is not supported in this browser. Enter the code contents manually.',
    qr_fallback_detect: 'QR detection is not available on this device. Enter the code contents manually.',
    qr_fallback_camera: 'Camera access was denied or is unavailable. Enter the code contents manually.',
    qr_fallback_context: 'Camera is not available in this context. Enter the code contents manually.',
    qr_status: 'Point the camera at a QR code — its contents will be added to the transaction.',
    about_text: '<b>Smart Finance 2.0</b> · local backend with SQLite or PostgreSQL · receipt recognition via the configured provider · category suggestions and expense forecast from the built-in analytics module.<br>Demo account: <b>demo / DemoFinance2026!</b>',
    auth_welcome: 'Your finances, in one place',
    auth_create: 'Create your account',
    auth_sub: 'Sign in to view your transactions and spending insights.',
    auth_sub_reg: 'Create an account to keep track of your transactions and spending insights.',
    username: 'Username', password: 'Password',
    signin: 'Sign in', create_acc: 'Create account',
    auth_have: 'Already have an account? Sign in', auth_new: 'New here? Create an account',
    personal_workspace: 'Personal workspace',
    stored_server: 'stored on the server',
    footer_note: 'Personal finance in KZT · Local workspace',
    ins_chip_all: 'all-time view',
    budget_of: 'of {x} limit',
    saved_toward: '{x} saved toward goals',
    no_budgets_yet: 'No savings goals yet',
    cats_word: 'categories',
    remaining: '{x} left', over_by_s: 'Over by {x}',
  },
  ru: {
    nav_overview: 'Обзор', nav_transactions: 'Транзакции', nav_insights: 'Аналитика', nav_planning: 'Планирование',
    tab_home: 'Главная', tab_history: 'История', tab_stats: 'Аналитика', tab_plans: 'Планы',
    hdr_snapshot: 'Финансовый снимок',
    greet_morning: 'Доброе утро', greet_afternoon: 'Добрый день', greet_evening: 'Добрый вечер',
    greet_sub: 'Вот что происходит с вашими деньгами.',
    btn_scan_receipt: 'Сканировать чек', btn_add_tx: 'Добавить транзакцию',
    banner_title: 'Сканировать чек',
    banner_text: 'Магазин, дата и сумма распознаются с фото. Подтверждённые категории запоминаются.',
    banner_btn: 'Скан',
    card_balance: 'Общий баланс', card_income: 'Доходы', card_expenses: 'Расходы',
    all_time: 'За всё время', this_month: 'в этом месяце', tx_word: 'транзакций', vs_last: 'к прошлому месяцу',
    new_activity: 'Новая активность', no_change: 'Без изменений',
    sec_cashflow: 'Денежный поток', sec_cashflow_sub: 'Доходы против расходов по времени',
    legend_income: 'Доходы', legend_expenses: 'Расходы', net_6: 'Итог {net} · {n} мес.',
    sec_budget: 'Месячный бюджет', sec_budget_sub: 'Держите расходы под контролем',
    spent_this_month: 'Потрачено в этом месяце', no_budget_note: 'Бюджетов пока нет — установите лимиты в Планировании.',
    manage_budgets: 'Управлять бюджетами', spent: 'потрачено', limit: 'лимит', of: 'из', over_by: 'Превышение на {x}',
    sec_recent: 'Последние транзакции', sec_recent_sub: 'Ваша последняя финансовая активность',
    view_all: 'Все', no_tx_short: 'Транзакций пока нет. Добавьте первый доход или расход.',
    sec_goals: 'Цели накоплений', sec_goals_sub: 'Маленькие шаги — большие планы',
    no_goals_ov: 'Целей пока нет', no_goals_ov_t: 'Создайте цель в Планировании и следите за прогрессом.',
    page_tx: 'Транзакции', page_tx_sub: 'Все доходы и расходы в одном месте.',
    import_csv: 'Импорт CSV', export_csv: 'Экспорт', scan_qr: 'Скан QR',
    tx_income_m: 'Доходы', tx_expenses_m: 'Расходы', tx_count_card: 'Транзакции',
    across: 'В {n} категориях',
    all_tx: 'Все транзакции', all_tx_sub: 'Просмотр и управление',
    search_ph: 'Поиск по описанию, категории…',
    all_types: 'Все типы', opt_income: 'Доходы', opt_expense: 'Расходы',
    all_categories: 'Все категории', all_months: 'Все месяцы',
    th_tx: 'Транзакция', th_category: 'Категория', th_date: 'Дата', th_type: 'Тип', th_amount: 'Сумма',
    today: 'Сегодня', yesterday: 'Вчера',
    showing: 'Показано {a}–{b} из {n} транзакций', no_tx_list: 'Нет транзакций',
    nothing_found: 'Ничего не найдено по фильтрам', try_another: 'Измените поиск или сбросьте фильтры.',
    no_tx_yet: 'Транзакций пока нет', no_tx_yet_t: 'Добавьте первый доход или расход.',
    amounts_note: 'Суммы в KZT (₸)',
    page_ins: 'Аналитика расходов', page_ins_sub: 'Ясная картина того, куда уходят деньги.',
    avg_daily: 'Средний расход в день', based_on: 'На основе {d} дней за {m}',
    top_category: 'Топ-категория', of_all: '{p}% всех расходов', no_exp_rec: 'Запишите расходы, чтобы увидеть',
    forecast_card: 'Прогноз · {m}', mean3: 'Среднее за последние 3 полных месяца',
    by_category: 'Расходы по категориям', total_spent: 'всего потрачено',
    smart_obs: 'Умные наблюдения', smart_obs_sub: 'Созданы из ваших записей',
    monthly_trend: 'Помесячный тренд', trend_sub: 'Расходы по месяцам, последние 12 месяцев',
    page_pl: 'Планирование', page_pl_sub: 'Стройте полезные привычки месяц за месяцем.',
    budget_used: 'Использовано бюджета', no_budget_for: 'Бюджетов на {m} нет',
    budget_cats: 'Категории бюджета', budget_cats_sub: 'Следите за лимитами',
    new_budget: 'Бюджет', new_goal_btn: 'Новая цель',
    goals_title: 'Цели накоплений', goals_sub: 'Ваш прогресс — на первый взгляд',
    target: 'Цель {x}', funded: '{p}% накоплено', goal_reached: 'Цель достигнута', to_go: 'осталось {x}',
    m_add_tx: 'Добавить транзакцию', m_amount: 'Сумма (KZT)', m_category: 'Категория', m_date: 'Дата',
    m_desc: 'Описание', suggest: 'Предложить категорию', save_tx: 'Сохранить транзакцию',
    m_qr_title: 'Сканировать QR-код',
    m_receipt: 'Сканировать чек', m_recognize: 'Распознать чек',
    m_import: 'Импорт из CSV',
    toast_saved: 'Транзакция сохранена.', toast_deleted: 'Транзакция удалена.',
    toast_refreshed: 'Данные обновлены.', toast_name_saved: 'Имя сохранено.',
    currency_display: 'Валюта (символ)', currency_note: 'Только символ — записи хранятся в KZT',
    donut_total: 'всего потрачено', all_recorded: 'Все записанные расходы',
    rows_per_page: 'Строк на странице', start_screen: 'Стартовый экран',
    theme_label: 'Тема', theme_light: 'Светлая', theme_dark: 'Тёмная', theme_system: 'Системная',
    hide_amounts: 'Скрывать суммы при запуске',
    toast_hidden: 'Суммы скрыты.', toast_visible: 'Суммы видны.',
    profile: 'Профиль', display_name: 'Отображаемое имя (на этом устройстве)', save_name: 'Сохранить имя',
    appearance: 'Внешний вид', about: 'О приложении', sign_out: 'Выйти',
    sec_data: 'Данные',
    acc_settings: 'Аккаунт и настройки',
    hdr_money: 'Движение ваших денег', hdr_insights: 'Поймите свои привычки', hdr_planning: 'Заставьте деньги работать',
    of_monthly_limit: '{p}% месячного лимита', across_goals: 'в {n} целях',
    spent_of: '{a} потрачено из {b}', all_expenses: 'Все расходы', add_funds: 'Пополнить',
    update_progress: 'Обновить прогресс', goal_reached_upd: 'Цель достигнута · изменить сумму',
    saved_of_pct: 'Накоплено {a} из {b} ({p}%).', add_amount_kzt: 'Сумма пополнения (KZT)', total_saved_kzt: 'Всего накоплено (KZT)',
    type_income: 'Доход', type_expense: 'Расход',
    obs_over_t: '{c} превышает бюджет', obs_over_d: 'Вы потратили {s} из лимита {l} за {m}. Проверьте в Планировании.',
    obs_top_t: '{c} — лидер расходов', obs_top_d: 'Это {p}% всех записанных расходов — стоит присмотреться.',
    obs_fc_t: 'Ожидаемые расходы в следующем месяце', obs_fc_d: 'Прозрачный базовый прогноз {x} на {m} — среднее за последние три полных месяца.',
    obs_goals_t: 'Продолжайте двигаться к целям', obs_goals_d: 'До завершения {w} осталось {x}. Небольшие переводы накапливаются.',
    obs_none_t: 'Продолжайте строить финансовую картину', obs_none_d: 'Записывайте транзакции и ставьте бюджеты — появятся полезные наблюдения.',
    disclaimer: 'Наблюдения созданы на основе ваших записей и не являются финансовой рекомендацией.',
    rec_card: 'Наблюдения расходов', warn_exceeded: 'Месячный бюджет превышен. Проверьте Планирование.',
    qr_status: 'Наведите камеру на QR-код — содержимое добавится в транзакцию.',
    in_month: 'в {m}', goal_one: 'цель', goals_word: 'цели',
    toast_budget: 'Бюджет сохранён.', toast_budget_del: 'Бюджет удалён.', toast_goal: 'Цель создана.',
    toast_goal_upd: 'Прогресс цели обновлён.', toast_goal_del: 'Цель удалена.', toast_goal_hit: 'Цель достигнута — поздравляем!',
    toast_qr: 'QR распознан — проверьте детали.', toast_rows: 'Строк на странице сохранено.',
    toast_start: 'Стартовый экран сохранён.', toast_cur: 'Валюта отображения: {c}',
    toast_priv_on: 'Суммы будут скрыты при запуске.', toast_priv_off: 'Суммы будут показаны при запуске.',
    toast_name: 'Имя сохранено.', toast_imported: 'Импортировано {n} транзакций.',
    toast_import_dup: 'Этот файл уже импортировался — дубликатов нет.',
    toast_exported: 'Экспортировано {n} транзакций.', toast_session: 'Сессия истекла — войдите снова.',
    toast_signed_out: 'Вы вышли из аккаунта.', toast_welcome: 'Добро пожаловать, {u}!',
    conf_del_tx: 'Удалить транзакцию?', conf_del_tx_d: '«{n}» будет безвозвратно удалена из вашего реестра.',
    conf_del_budget: 'Удалить бюджет?', conf_del_budget_d: 'Лимит «{c}» на {m} будет удалён. Транзакции не затронуты.',
    conf_del_goal: 'Удалить цель?', conf_del_goal_d: '«{n}» будет удалена. Уже накопленное остаётся в реестре.',
    conf_sign_out: 'Выйти из аккаунта?', conf_sign_out_d: 'Токен сессии будет отозван на сервере. Данные остаются сохранены.',
    m_budget_t: 'Новый бюджет', m_budget_edit: 'Изменить бюджет', m_budget_cat: 'Категория', m_budget_all: 'Все расходы (итог)',
    m_budget_month: 'Месяц', m_budget_limit: 'Месячный лимит (KZT)', m_budget_save: 'Сохранить изменения',
    m_goal_t: 'Новая цель накоплений', m_goal_name: 'Название цели', m_goal_target: 'Целевая сумма (KZT)', m_goal_saved: 'Уже накоплено (KZT, необязательно)',
    m_goal_create: 'Создать цель', m_topup_t: 'Пополнить', m_topup_edit: 'Обновить накопленное',
    m_tx_t: 'Добавить транзакцию', m_quick: 'Быстрый ввод', m_expense: '− Расход', m_income_p: '＋ Доход',
    m_amount_kzt: 'Сумма (KZT)', m_type: 'Тип', m_desc_ph: 'например, Продукты на неделю',
    m_cancel: 'Отмена', m_save_budget: 'Сохранить изменения',
    r_consent: 'Я согласен отправить фото чека настроенному провайдеру распознавания. Для демо используйте образец чека; не загружайте чувствительные личные данные.',
    r_drop: 'Перетащите фото чека или выберите', r_recognize: 'Распознать чек',

    lang_title: 'Язык · Тіл · Language',
    qr_fallback_browser: 'Сканирование QR не поддерживается в этом браузере. Введите содержимое вручную.',
    qr_fallback_detect: 'Распознавание QR недоступно на этом устройстве. Введите содержимое вручную.',
    qr_fallback_camera: 'Доступ к камере отклонён или недоступен. Введите содержимое вручную.',
    qr_fallback_context: 'Камера недоступна в этом контексте. Введите содержимое вручную.',
    qr_status: 'Наведите камеру на QR-код — содержимое добавится в транзакцию.',
    about_text: '<b>Smart Finance 2.0</b> · локальный бэкенд с SQLite или PostgreSQL · распознавание чеков через настроенного провайдера · подсказки категорий и прогноз расходов встроенного аналитического модуля.<br>Демо-аккаунт: <b>demo / DemoFinance2026!</b>',
    auth_welcome: 'Ваши финансы — в одном месте',
    auth_create: 'Создать аккаунт',
    auth_sub: 'Войдите, чтобы увидеть транзакции и аналитику расходов.',
    auth_sub_reg: 'Создайте аккаунт, чтобы вести транзакции и видеть аналитику.',
    username: 'Имя пользователя', password: 'Пароль',
    signin: 'Войти', create_acc: 'Создать аккаунт',
    auth_have: 'Уже есть аккаунт? Войти', auth_new: 'Впервые здесь? Создайте аккаунт',
    personal_workspace: 'Личное пространство',
    stored_server: 'хранится на сервере',
    footer_note: 'Личные финансы в KZT · Локальное приложение',
    ins_chip_all: 'за всё время',
    budget_of: 'из {x} лимита',
    saved_toward: '{x} накоплено на цели',
    no_budgets_yet: 'Целей пока нет',
    cats_word: 'категориях',
    remaining: 'осталось {x}', over_by_s: 'Сверх на {x}',
  },
  kz: {
    nav_overview: 'Басты бет', nav_transactions: 'Транзакциялар', nav_insights: 'Талдау', nav_planning: 'Жоспарлау',
    tab_home: 'Басты бет', tab_history: 'Тарих', tab_stats: 'Талдау', tab_plans: 'Жоспарлар',
    hdr_snapshot: 'Қаржылық шолу',
    greet_morning: 'Қайырлы таң', greet_afternoon: 'Қайырлы күн', greet_evening: 'Қайырлы кеш',
    greet_sub: 'Ақшаңызбен не болып жатқаны — осында.',
    btn_scan_receipt: 'Чек сканерлеу', btn_add_tx: 'Транзакция қосу',
    banner_title: 'Чек сканерлеу',
    banner_text: 'Дүкен, күн және сома суреттен оқылады. Расталған категориялар есте сақталады.',
    banner_btn: 'Сканерлеу',
    card_balance: 'Жалпы баланс', card_income: 'Табыс', card_expenses: 'Шығын',
    all_time: 'Барлық уақытта', this_month: 'осы айда', tx_word: 'транзакция', vs_last: 'өткен айға қарағанда',
    new_activity: 'Жаңа белсенділік', no_change: 'Өзгеріс жоқ',
    sec_cashflow: 'Ақша ағымы', sec_cashflow_sub: 'Табыс пен шығын уақыт бойынша',
    legend_income: 'Табыс', legend_expenses: 'Шығын', net_6: 'Нәтиже {net} · {n} ай',
    sec_budget: 'Айлық бюджет', sec_budget_sub: 'Шығынды бақылауда ұстаңыз',
    spent_this_month: 'Осы айда жұмсалды', no_budget_note: 'Бюджет жоқ — лимиттерді Жоспарлауда қойыңыз.',
    manage_budgets: 'Бюджеттерді басқару', spent: 'жұмсалды', limit: 'лимит', of: '/', over_by: 'Асырып жіберді: {x}',
    sec_recent: 'Соңғы транзакциялар', sec_recent_sub: 'Соңғы қаржылық белсенділігіңіз',
    view_all: 'Барлығы', no_tx_short: 'Транзакция жоқ. Алғашқы табысыңызды немесе шығысыңызды қосыңыз.',
    sec_goals: 'Жинау мақсаттары', sec_goals_sub: 'Кішкене қадамдар — үлкен жоспарлар',
    no_goals_ov: 'Мақсат жоқ', no_goals_ov_t: 'Жоспарлауда мақсат қойып, прогресс сақинасын толтырыңыз.',
    page_tx: 'Транзакциялар', page_tx_sub: 'Барлық табыс пен шығын бір жерде.',
    import_csv: 'CSV импорттау', export_csv: 'Экспорттау', scan_qr: 'QR сканерлеу',
    tx_income_m: 'Табыс', tx_expenses_m: 'Шығын', tx_count_card: 'Транзакциялар',
    across: '{n} категория бойынша',
    all_tx: 'Барлық транзакциялар', all_tx_sub: 'Қарап шығу және басқару',
    search_ph: 'Сипаттама, категория бойынша іздеу…',
    all_types: 'Барлық түрі', opt_income: 'Табыс', opt_expense: 'Шығын',
    all_categories: 'Барлық категория', all_months: 'Барлық ай',
    th_tx: 'Транзакция', th_category: 'Категория', th_date: 'Күн', th_type: 'Түрі', th_amount: 'Сома',
    today: 'Бүгін', yesterday: 'Кеше',
    showing: '{a}–{b}, барлығы {n} транзакция', no_tx_list: 'Транзакция жоқ',
    nothing_found: 'Сүзгі бойынша ештеңе табылмады', try_another: 'Іздеуді өзгертіңіз немесе сүзгіні алыңыз.',
    no_tx_yet: 'Транзакция жоқ', no_tx_yet_t: 'Алғашқы табысыңызды немесе шығысыңызды қосыңыз.',
    amounts_note: 'Сомалар KZT (₸) түрінде',
    page_ins: 'Шығын талдауы', page_ins_sub: 'Ақшаңыз қайда кететіні — анық көрініс.',
    avg_daily: 'Күндізгі орташа шығын', based_on: '{m} айының {d} күні негізінде',
    top_category: 'Үздік категория', of_all: 'барлық шығынның {p}%', no_exp_rec: 'Көру үшін шығын жазыңыз',
    forecast_card: 'Болжам · {m}', mean3: 'Соңғы 3 толық айдың орташа мәні',
    by_category: 'Категориялар бойынша шығын', total_spent: 'барлығы жұмсалды',
    smart_obs: 'Ақылды бақылаулар', smart_obs_sub: 'Сіздің жазбаларыңыздан құрылған',
    monthly_trend: 'Айлық тренд', trend_sub: 'Ай сайынғы шығын, соңғы 12 ай',
    page_pl: 'Жоспарлау', page_pl_sub: 'Ай сайын пайдалы әдеттер қалыптастырыңыз.',
    budget_used: 'Пайдаланылған бюджет', no_budget_for: '{m} айына бюджет жоқ',
    budget_cats: 'Бюджет категориялары', budget_cats_sub: 'Лимиттерді бақылаңыз',
    new_budget: 'Бюджет', new_goal_btn: 'Жаңа жинау мақсаты',
    goals_title: 'Жинау мақсаттары', goals_sub: 'Прогресіңіз — бір көзқарасқа',
    target: 'Мақсат {x}', funded: '{p}% жиналды', goal_reached: 'Мақсатқа қол жетті', to_go: '{x} қалды',
    m_add_tx: 'Транзакция қосу', m_amount: 'Сома (KZT)', m_category: 'Категория', m_date: 'Күн',
    m_desc: 'Сипаттама', suggest: 'Категория ұсыну', save_tx: 'Транзакцияны сақтау',
    m_qr_title: 'QR кодты сканерлеу',
    m_receipt: 'Чек сканерлеу', m_recognize: 'Чекті тану',
    m_import: 'CSV-ден импорттау',
    toast_saved: 'Транзакция сақталды.', toast_deleted: 'Транзакция өшірілді.',
    toast_refreshed: 'Деректер жаңартылды.', toast_name_saved: 'Атау сақталды.',
    currency_display: 'Валюта (таңба)', currency_note: 'Тек таңба — жазбалар KZT түрінде',
    donut_total: 'барлығы жұмсалды', all_recorded: 'Барлық жазылған шығын',
    rows_per_page: 'Беттегі жол саны', start_screen: 'Бастапқы экран',
    theme_label: 'Тема', theme_light: 'Жарық', theme_dark: 'Қараңғы', theme_system: 'Жүйе',
    hide_amounts: 'Бастауышда сомаларды жасыру',
    toast_hidden: 'Сомалар жасырылды.', toast_visible: 'Сомалар көрінеді.',
    profile: 'Профиль', display_name: 'Атау (бұл құрылғыда)', save_name: 'Атауды сақтау',
    appearance: 'Сыртқы түрі', about: 'Қолданба туралы', sign_out: 'Шығу',
    sec_data: 'Деректер',
    acc_settings: 'Аккаунт мен параметрлер',
    hdr_money: 'Ақшаның қозғалысы', hdr_insights: 'Әдеттеріңізді түсініңіз', hdr_planning: 'Ақшаны тиімді жұмсаңыз',
    of_monthly_limit: 'айлық лимиттің {p}%', across_goals: '{n} мақсат бойынша',
    spent_of: '{a} жұмсалды, барлығы {b}', all_expenses: 'Барлық шығын', add_funds: 'Қаражат қосу',
    update_progress: 'Прогресті жаңарту', goal_reached_upd: 'Мақсатқа қол жетті · соманы өзгерту',
    saved_of_pct: 'Жиналды {a} / {b} ({p}%).', add_amount_kzt: 'Қосылатын сома (KZT)', total_saved_kzt: 'Барлығы жиналды (KZT)',
    type_income: 'Табыс', type_expense: 'Шығын',
    obs_over_t: '{c} бюджеттен асты', obs_over_d: '{m} айында {l} лимитінің {s} жұмсадыңыз. Жоспарлауда қарап шығыңыз.',
    obs_top_t: '{c} — шығын көшбасшысы', obs_top_d: 'Жазылған шығынның {p}% — қысқартуды ойласаңыз, назар аударыңыз.',
    obs_fc_t: 'Келесі айдағы күтілетін шығын', obs_fc_d: '{m} айына мөлдір базалық болжам {x} — соңғы үш толық айдың орташа мәні.',
    obs_goals_t: 'Мақсаттарға бетбұрысты сақтаңыз', obs_goals_d: '{w} аяқталуға {x} қалды. Кішкене аударымдар жинақталады.',
    obs_none_t: 'Қаржылық көрінісіңізді толықтыра түсіңіз', obs_none_d: 'Транзакцияларды жазып, бюджет қойыңыз — пайдалы бақылаулар пайда болады.',
    disclaimer: 'Бақылаулар сіздің жазбаларыңыздан құрылған және қаржылық кеңес емес.',
    rec_card: 'Шығын бақылаулары', warn_exceeded: 'Айлық бюджет асты. Жоспарлауды қарап шығыңыз.',
    qr_status: 'Камераны QR кодқа бағыттаңыз — мазмұны транзакцияға қосылады.',
    in_month: '{m} айында', goal_one: 'мақсат', goals_word: 'мақсаттар',
    toast_budget: 'Бюджет сақталды.', toast_budget_del: 'Бюджет өшірілді.', toast_goal: 'Мақсат жасалды.',
    toast_goal_upd: 'Мақсат прогресі жаңартылды.', toast_goal_del: 'Мақсат өшірілді.', toast_goal_hit: 'Мақсатқа қол жетті — құттықтаймыз!',
    toast_qr: 'QR оқылды — деректерді тексеріңіз.', toast_rows: 'Беттегі жол саны сақталды.',
    toast_start: 'Бастапқы экран сақталды.', toast_cur: 'Көрсетілетін валюта: {c}',
    toast_priv_on: 'Іске қосылғанда сомалар жасырылады.', toast_priv_off: 'Іске қосылғанда сомалар көрінеді.',
    toast_name: 'Атау сақталды.', toast_imported: '{n} транзакция импортталды.',
    toast_import_dup: 'Бұл файл бұрын импортталған — қайталанбағы жоқ.',
    toast_exported: '{n} транзакция экспортталды.', toast_session: 'Сессия аяқталды — қайта кіріңіз.',
    toast_signed_out: 'Аккаунттан шықтыңыз.', toast_welcome: 'Қош келдіңіз, {u}!',
    conf_del_tx: 'Транзакцияны өшіру?', conf_del_tx_d: '«{n}» реестрден мәңгі өшіріледі.',
    conf_del_budget: 'Бюджетті өшіру?', conf_del_budget_d: '{m} айындағы «{c}» лимиті өшіріледі. Транзакцияларға әсер жоқ.',
    conf_del_goal: 'Мақсатты өшіру?', conf_del_goal_d: '«{n}» өшіріледі. Жиналған қаражат реестрде қалады.',
    conf_sign_out: 'Аккаунттан шығу?', conf_sign_out_d: 'Сессия токені серверде өшіріледі. Деректер сақталып қалады.',
    m_budget_t: 'Жаңа бюджет', m_budget_edit: 'Бюджетті өзгерту', m_budget_cat: 'Категория', m_budget_all: 'Барлық шығын (жалпы)',
    m_budget_month: 'Ай', m_budget_limit: 'Айлық лимит (KZT)', m_budget_save: 'Өзгерістерді сақтау',
    m_goal_t: 'Жаңа жинау мақсаты', m_goal_name: 'Мақсат атауы', m_goal_target: 'Мақсат сомасы (KZT)', m_goal_saved: 'Қазір жиналған (KZT, қалауыңызбойынша)',
    m_goal_create: 'Мақсат жасау', m_topup_t: 'Қаражат қосу', m_topup_edit: 'Жиналғанды жаңарту',
    m_tx_t: 'Транзакция қосу', m_quick: 'Жылдам енгізу', m_expense: '− Шығын', m_income_p: '＋ Табыс',
    m_amount_kzt: 'Сома (KZT)', m_type: 'Түрі', m_desc_ph: 'мысалы, Апталық сөрілік',
    m_cancel: 'Болдырмау', m_save_budget: 'Өзгерістерді сақтау',
    r_consent: 'Бұл чек суретін теңшелген тану провайдеріне жібергеніме келісемін. Демо үшін үлгі чекті пайдаланыңыз; жеке деректерді жүктемеңіз.',
    r_drop: 'Чек суретін тастаңыз немесе таңдаңыз', r_recognize: 'Чекті тану',

    lang_title: 'Тіл · Язык · Language',
    qr_fallback_browser: 'Бұл браузерде QR сканерлеу қолдау көрсетілмейді. Мазмұнды қолмен енгізіңіз.',
    qr_fallback_detect: 'Бұл құрылғыда QR тану қолжетімсіз. Мазмұнды қолмен енгізіңіз.',
    qr_fallback_camera: 'Камераға рұқсат жоқ немесе қолжетімсіз. Мазмұнды қолмен енгізіңіз.',
    qr_fallback_context: 'Осы контекстте камера қолжетімсіз. Мазмұнды қолмен енгізіңіз.',
    qr_status: 'Камераны QR кодқа бағыттаңыз — мазмұны транзакцияға қосылады.',
    about_text: '<b>Smart Finance 2.0</b> · жергілікті бэкенд (SQLite немесе PostgreSQL) · чекті тану — теңшелген провайдер арқылы · категория ұсыныстары мен шығын болжамы — кірістірілген аналитикалық модульден.<br>Демо-аккаунт: <b>demo / DemoFinance2026!</b>',
    auth_welcome: 'Қаржыңыз — бір жерде',
    auth_create: 'Аккаунт жасау',
    auth_sub: 'Транзакциялар мен шығын талдауын көру үшін кіріңіз.',
    auth_sub_reg: 'Транзакцияларды жүргізу және талдауды көру үшін аккаунт жасаңыз.',
    username: 'Пайдаланушы аты', password: 'Құпиясөз',
    signin: 'Кіру', create_acc: 'Аккаунт жасау',
    auth_have: 'Аккаунтыңыз бар ма? Кіру', auth_new: 'Алғаш рет келдіңіз бе? Аккаунт жасаңыз',
    personal_workspace: 'Жеке кеңістік',
    stored_server: 'серверде сақтаулы',
    footer_note: 'KZT жеке қаржы · Жергілікті қолданба',
    ins_chip_all: 'барлық уақыт бойынша',
    budget_of: 'лимит {x}',
    saved_toward: 'Мақсатқа {x} жиналды',
    no_budgets_yet: 'Мақсат жоқ',
    cats_word: 'категория',
    remaining: '{x} қалды', over_by_s: 'Асырды: {x}',
  },
};

let LANG = localStorage.getItem('sf_lang') || 'en';
const LOCALE = { en: 'en-US', ru: 'ru-RU', kz: 'kk-KZ' };

function t(key, vars) {
  let text = (I18N[LANG] && I18N[LANG][key]) || I18N.en[key] || key;
  if (vars) for (const [k, v] of Object.entries(vars)) {
    text = text.replace('{' + k + '}', v);
  }
  return text;
}

function applyI18n() {
  document.documentElement.lang = { en: 'en', ru: 'ru', kz: 'kk' }[LANG] || 'en';
  document.querySelectorAll('[data-i18n]').forEach((el) => {
    const v = I18N[LANG] && I18N[LANG][el.dataset.i18n];
    if (v !== undefined) el.textContent = v;
  });
  document.querySelectorAll('[data-i18n-ph]').forEach((el) => {
    const v = I18N[LANG] && I18N[LANG][el.dataset.i18nPh];
    if (v !== undefined) el.placeholder = v;
  });
  document.querySelectorAll('.flag-btn').forEach((b) => b.classList.toggle('active', b.dataset.lang === LANG));
}

function flagSvg(code) {
  if (code === 'kz') {
    return '<svg class="flag" viewBox="0 0 20 14"><rect width="20" height="14" rx="2.5" fill="#00AFCA"/><circle cx="10" cy="7" r="2.6" fill="#FEC50C"/></svg>';
  }
  if (code === 'ru') {
    return '<svg class="flag" viewBox="0 0 20 14"><rect width="20" height="4.7" rx="2.5" fill="#ffffff"/><rect y="4.7" width="20" height="4.6" fill="#0039A6"/><rect y="9.3" width="20" height="4.7" fill="#D52B1E"/><rect width="20" height="14" rx="2.5" fill="none" stroke="rgba(0,0,0,.18)"/></svg>';
  }
  return '<svg class="flag" viewBox="0 0 20 14"><rect width="20" height="14" rx="2.5" fill="#012169"/><path d="M0 0l20 14M20 0L0 14" stroke="#ffffff" stroke-width="2.6"/><path d="M0 0l20 14M20 0L0 14" stroke="#C8102E" stroke-width="1.1"/><path d="M10 0v14M0 7h20" stroke="#ffffff" stroke-width="3.6"/><path d="M10 0v14M0 7h20" stroke="#C8102E" stroke-width="2"/></svg>';
}

/* ---------- 2. State ---------- */
const settings = {
  displayName: localStorage.getItem('sf_display_name') || '',
  rows: Number(localStorage.getItem('sf_rows')) || 10,
  privacyStart: localStorage.getItem('sf_privacy_start') === '1',
  startPage: localStorage.getItem('sf_start_page') || 'overview',
  theme: localStorage.getItem('sf_theme') || 'dark',
  currency: localStorage.getItem('sf_currency') || 'KZT',
};
const state = {
  settings,
  token: localStorage.getItem('sf_token') || '',
  user: null,
  transactions: [],
  summary: { income_minor: 0, expense_minor: 0, balance_minor: 0, month_income_minor: 0, month_expense_minor: 0, transaction_count: 0 },
  analytics: FALLBACK_ANALYTICS,
  goals: [],
  budgets: [],
  planMonth: currentMonthKey(),
  filters: { q: '', type: 'all', category: 'all', month: 'all', page: 1 },
  ready: false,
};
PAGE_SIZE = settings.rows;

/* ---------- 3. Utilities ---------- */
const $ = (id) => document.getElementById(id);

function esc(value) {
  return String(value ?? '').replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}

function icon(name, cls = 'icon') {
  return `<svg class="${cls}" aria-hidden="true"><use href="#${name}"/></svg>`;
}

function currencySymbol() {
  return CURRENCIES[settings.currency] || '₸';
}

function fmtMoney(minor) {
  const value = Number(minor);
  if (!Number.isFinite(value)) return currencySymbol() + ' 0';
  return currencySymbol() + ' ' + (value / 100).toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 2 });
}

function fmtCompact(minor) {
  const sym = currencySymbol();
  const v = Number(minor) / 100;
  if (!Number.isFinite(v) || v === 0) return '0';
  if (Math.abs(v) >= 1e6) return sym + (v / 1e6).toFixed(Math.abs(v) >= 1e7 ? 0 : 1).replace(/\.0$/, '') + 'm';
  if (Math.abs(v) >= 1000) return sym + Math.round(v / 1000) + 'k';
  return sym + Math.round(v);
}

function fmtDate(iso) {
  const raw = String(iso || '').slice(0, 10);
  const d = new Date(raw + 'T00:00:00');
  if (Number.isNaN(d.getTime())) return raw;
  if (LANG === 'kz') {
    return `${d.getDate()} ${KZ_MONTHS_SHORT[d.getMonth()]} ${d.getFullYear()}`;
  }
  return d.toLocaleDateString(LOCALE[LANG] || 'en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function monthKeyOf(d) {
  return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0');
}

function currentMonthKey() {
  return monthKeyOf(new Date());
}

const KZ_MONTHS = ['Қаңтар', 'Ақпан', 'Наурыз', 'Сәуір', 'Мамыр', 'Маусым', 'Шілде', 'Тамыз', 'Қыркүйек', 'Қазан', 'Қараша', 'Желтоқсан'];
const KZ_MONTHS_SHORT = ['Қаң', 'Ақп', 'Нау', 'Сәу', 'Мам', 'Мау', 'Шіл', 'Там', 'Қыр', 'Қаз', 'Қар', 'Жел'];

function monthLabel(key, style) {
  const [y, m] = String(key).split('-').map(Number);
  if (LANG === 'kz') {
    const mi = (m || 1) - 1;
    return style === 'short' ? KZ_MONTHS_SHORT[mi] : `${KZ_MONTHS[mi]} ${y}`;
  }
  const d = new Date(y, (m || 1) - 1, 1);
  const loc = LOCALE[LANG] || 'en-US';
  return d.toLocaleString(loc, style === 'short' ? { month: 'short' } : { month: 'long', year: 'numeric' });
}

function shiftMonth(key, delta) {
  const [y, m] = key.split('-').map(Number);
  const d = new Date(y, m - 1 + delta, 1);
  return monthKeyOf(d);
}

function todayISO() {
  const d = new Date();
  return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
}

function catClass(name) {
  const slug = String(name || '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
  return CAT_META[name] || name === '*' ? 'cat-' + (slug || 'other') : 'cat-' + (slug || 'unknown');
}

function catMeta(name) {
  if (CAT_META[name]) return CAT_META[name];
  if (name === '*') return { icon: 'i-wallet', color: '#0D4F3C' };
  return CAT_META.Other;
}

function catLabel(name) {
  return name === '*' ? 'All expenses' : name;
}

function catLabelT(name) {
  if (name === '*') return t('all_expenses');
  return (CAT_I18N[LANG] && CAT_I18N[LANG][name]) || name;
}

function progressClass(pct) {
  if (pct > 100) return 'over';
  if (pct >= 75) return 'warn';
  return 'ok';
}

function percentOf(spent, limit) {
  if (!limit) return 0;
  return Math.round((spent / limit) * 100);
}

function ringSvg(pct) {
  const C = 2 * Math.PI * 19;
  const clamped = Math.max(0, Math.min(100, pct));
  const offset = (C * (1 - clamped / 100)).toFixed(1);
  return `<svg class="ring" viewBox="0 0 44 44" aria-hidden="true"><circle class="ring-bg" cx="22" cy="22" r="19"/><circle class="ring-val${clamped >= 100 ? ' done' : ''}" cx="22" cy="22" r="19" style="stroke-dasharray:${C.toFixed(1)};stroke-dashoffset:${offset}"/></svg>`;
}

function initials(name) {
  const clean = String(name || '?').trim();
  return clean.slice(0, 2).toUpperCase();
}

/* ---------- 4. API client ---------- */
class ApiError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
    this.handled = false;
  }
}

async function request(path, opts = {}) {
  const headers = { ...(opts.headers || {}) };
  if (state.token) headers.Authorization = 'Bearer ' + state.token;
  if (opts.body !== undefined && !(opts.body instanceof Blob)) {
    headers['Content-Type'] = headers['Content-Type'] || 'application/json';
  }
  let response;
  try {
    response = await fetch(API + path, { ...opts, headers });
  } catch (networkError) {
    throw new ApiError('The server is not reachable.', 0);
  }
  let data = {};
  try { data = await response.json(); } catch (_) { /* non-JSON response */ }
  if (!response.ok) throw new ApiError(data.error || `Request failed (${response.status})`, response.status);
  return data;
}

async function api(path, opts = {}) {
  try {
    return await request(path, opts);
  } catch (err) {
    if (err instanceof ApiError && err.status === 401 && state.ready) {
      err.handled = true;
      signOut(t('toast_session'));
    }
    throw err;
  }
}

/* ---------- 5. Toasts ---------- */
function toast(message, type = 'success') {
  const stack = $('toastStack');
  if (!stack) return;
  stack.querySelectorAll('.toast').forEach((existing) => {
    if (existing.dismissTimer) clearTimeout(existing.dismissTimer);
    existing.remove();
  });
  const icons = { success: 'i-check', error: 'i-alert', info: 'i-info' };
  const el = document.createElement('div');
  el.className = 'toast ' + type;
  el.innerHTML = icon(icons[type] || 'i-info', 'icon') + '<span>' + esc(message) + '</span>';
  stack.append(el);
  el.dismissTimer = setTimeout(() => {
    el.classList.add('out');
    setTimeout(() => el.remove(), 220);
  }, type === 'error' ? 2800 : 1700);
}

/* ---------- 6. Modal system ---------- */
function openModal(html, { narrow = false, onClose, rootId = 'modalRoot' } = {}) {
  const root = $(rootId);
  root.innerHTML = `<div class="modal-backdrop open"><div class="modal${narrow ? ' narrow' : ''}" role="dialog" aria-modal="true">${html}</div></div>`;
  const backdrop = root.firstElementChild;
  const box = backdrop.querySelector('.modal');
  document.body.style.overflow = 'hidden';

  let closeHook = onClose;
  function close(silent = false) {
    root.innerHTML = '';
    if (!$('modalRoot').innerHTML && !$('qrRoot').innerHTML) document.body.style.overflow = '';
    document.removeEventListener('keydown', onKey);
    if (!silent && closeHook) closeHook();
  }
  function onKey(e) { if (e.key === 'Escape') close(); }
  document.addEventListener('keydown', onKey);
  backdrop.addEventListener('mousedown', (e) => { if (e.target === backdrop) close(); });
  backdrop.querySelectorAll('[data-close]').forEach((btn) => btn.addEventListener('click', () => close()));
  const first = box.querySelector('input, select, textarea, button:not([data-close])');
  if (first) first.focus();
  return { root: backdrop, box, close, setCloseHook(fn) { closeHook = fn; } };
}

function confirmDialog({ title, message, confirmLabel = 'Delete' }) {
  return new Promise((resolve) => {
    let settled = false;
    const settle = (value) => { if (!settled) { settled = true; resolve(value); } };
    const modal = openModal(`
      <div class="modal-head"><div><div class="eyebrow">Please confirm</div><h2>${esc(title)}</h2></div>
      <button type="button" class="icon-ghost" data-close aria-label="Close">${icon('i-x', 'icon sm')}</button></div>
      <span class="tip-icon red" style="display:inline-grid;margin-bottom:14px">${icon('i-alert')}</span>
      <p class="muted" style="font-size:12.5px;line-height:1.6">${esc(message)}</p>
      <div class="modal-actions">
        <button type="button" class="btn ghost" data-close>Cancel</button>
        <button type="button" class="btn danger" id="confirmYes">${esc(confirmLabel)}</button>
      </div>`, {
      narrow: true,
      onClose: () => settle(false),
    });
    modal.box.querySelector('#confirmYes').addEventListener('click', () => {
      modal.close(true);
      settle(true);
    });
  });
}

/* ---------- 7. Derived data helpers ---------- */
function monthBuckets(count) {
  const now = new Date();
  const buckets = [];
  for (let i = count - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    buckets.push({ key: monthKeyOf(d), date: d, income: 0, expense: 0 });
  }
  const index = new Map(buckets.map((b) => [b.key, b]));
  for (const t of state.transactions) {
    const bucket = index.get(String(t.created_at || '').slice(0, 7));
    if (!bucket) continue;
    if (t.kind === 'income') bucket.income += Number(t.amount_minor) || 0;
    else if (t.kind === 'expense') bucket.expense += Number(t.amount_minor) || 0;
  }
  return buckets;
}

function bucketFor(key) {
  return monthBuckets(12).find((b) => b.key === key) || { key, income: 0, expense: 0 };
}

function trendOf(current, previous) {
  if (!previous) return { cls: 'flat', text: t('new_activity'), pct: null };
  const pct = ((current - previous) / previous) * 100;
  if (Math.abs(pct) < 0.05) return { cls: 'flat', text: '0%', pct: 0 };
  return { cls: pct > 0 ? 'up' : 'down', text: Math.abs(pct).toFixed(1) + '%', pct };
}

function niceMax(value) {
  if (value <= 0) return 1;
  const power = Math.pow(10, Math.floor(Math.log10(value)));
  for (const m of [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]) {
    if (m * power >= value) return m * power;
  }
  return 10 * power;
}

function countUp(el) {
  const target = Number(el?.dataset.count);
  if (!el || !Number.isFinite(target)) return;
  if (REDUCED_MOTION) { el.textContent = fmtMoney(target); return; }
  const start = performance.now();
  const duration = 600;
  function frame(now) {
    const t = Math.min(1, (now - start) / duration);
    const eased = 1 - Math.pow(1 - t, 3);
    el.textContent = fmtMoney(Math.round(target * eased));
    if (t < 1) requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
}

function animateAmounts(scope) {
  (scope || document).querySelectorAll('[data-count]').forEach(countUp);
}

function fillSkeleton(el, rows = 3) {
  if (!el) return;
  let html = '';
  for (let i = 0; i < rows; i++) html += `<div class="skeleton block" style="height:${i % 2 ? 34 : 58}px;margin-bottom:12px"></div>`;
  el.innerHTML = html;
}

/* ---------- 8. Charts ---------- */
function barChartTooltipEvents(mount, svg, buckets) {
  const tip = mount.querySelector('.chart-tip');
  if (!tip) return;
  const mountBox = mount.getBoundingClientRect();
  mount.querySelectorAll('.cf-group').forEach((group) => {
    const i = Number(group.dataset.i);
    const bucket = buckets[i];
    function show() {
      const svgBox = svg.getBoundingClientRect();
      const scaleX = svgBox.width / 640;
      const scaleY = svgBox.height / 260;
      const net = bucket.income - bucket.expense;
      tip.innerHTML = `<b>${monthLabel(bucket.key)}</b>`
        + `<div class="tip-row"><i class="dot inc"></i>Income<strong>${fmtMoney(bucket.income)}</strong></div>`
        + `<div class="tip-row"><i class="dot exp"></i>Expenses<strong>${fmtMoney(bucket.expense)}</strong></div>`
        + `<div class="tip-row net">Net<strong class="${net < 0 ? 'negative' : ''}">${net < 0 ? '−' : '+'}${fmtMoney(Math.abs(net))}</strong></div>`;
      tip.hidden = false;
      const slot = 628 / buckets.length;
      const centerX = svgBox.left - mountBox.left + (6 + slot * i + slot / 2) * scaleX;
      const topY = svgBox.top - mountBox.top + Math.max(24, 232 - (Math.max(bucket.income, bucket.expense) / niceMax(Math.max(...buckets.map((b) => Math.max(b.income, b.expense), 1)))) * 208) * scaleY;
      tip.style.left = Math.max(6, Math.min(mountBox.width - tip.offsetWidth - 6, centerX - tip.offsetWidth / 2)) + 'px';
      tip.style.top = Math.max(4, topY - tip.offsetHeight - 10) + 'px';
    }
    group.addEventListener('mouseenter', show);
    group.addEventListener('mouseleave', () => { tip.hidden = true; });
  });
}

function renderCashflow() {
  const mount = $('cashChart');
  if (!mount) return;
  const months = state.cashflowMonths || 6;
  const buckets = monthBuckets(months);
  const net = buckets.reduce((sum, b) => sum + b.income - b.expense, 0);
  $('cashNet').innerHTML = `${t('net_6', { net: (net < 0 ? '−' : '+') + fmtMoney(Math.abs(net)), n: months })}`;
  if (buckets.every((b) => !b.income && !b.expense)) {
    mount.innerHTML = `<div class="empty"><span class="empty-icon">${icon('i-swap')}</span><strong>No cash flow yet</strong><p>Add your first income or expense and your last six months will appear here.</p></div>`;
    return;
  }
  const scale = niceMax(Math.max(...buckets.map((b) => Math.max(b.income, b.expense)), 1));
  const base = 232, top = 24, span = base - top;
  const slot = 628 / buckets.length;
  let grids = '';
  for (const f of [1, 0.75, 0.5, 0.25]) {
    const y = (base - f * span).toFixed(1);
    grids += `<line class="cf-grid" x1="6" x2="634" y1="${y}" y2="${y}"/>`;
  }
  let groups = '';
  buckets.forEach((b, i) => {
    const cx = 6 + slot * i + slot / 2;
    const incH = Math.round((b.income / scale) * span);
    const expH = Math.round((b.expense / scale) * span);
    const inc = incH > 0 ? `<rect class="cf-bar inc" x="${(cx - 24).toFixed(1)}" y="${base - incH}" width="22" height="${incH}" rx="6"/>` : '';
    const exp = expH > 0 ? `<rect class="cf-bar exp" x="${(cx + 2).toFixed(1)}" y="${base - expH}" width="22" height="${expH}" rx="6"/>` : '';
    groups += `<g class="cf-group" data-i="${i}">${inc}${exp}<text class="cf-xlabel" x="${cx.toFixed(1)}" y="252" text-anchor="middle">${monthLabel(b.key, 'short')}</text></g>`;
  });
  const yAxis = [1, 0.75, 0.5, 0.25, 0].map((f) => `<span>${f === 0 ? '0' : fmtCompact(scale * f)}</span>`).join('');
  mount.innerHTML = `
    <div class="legend"><span><i class="dot inc"></i>Income</span><span><i class="dot exp"></i>Expenses</span></div>
    <div class="chart-frame"><div class="cf-yaxis">${yAxis}</div>
      <svg class="cf-svg" viewBox="0 0 640 260" role="img" aria-label="Cash flow, last six months">${grids}<line class="cf-grid" x1="6" x2="634" y1="${base}" y2="${base}"/>${groups}</svg>
      <div class="chart-tip" hidden></div>
    </div>`;
  barChartTooltipEvents(mount, mount.querySelector('svg'), buckets);
}

function renderTrendChart() {
  const mount = $('trendChart');
  if (!mount) return;
  const buckets = monthBuckets(12);
  if (buckets.every((b) => !b.expense)) {
    mount.innerHTML = `<div class="empty"><span class="empty-icon">${icon('i-pie')}</span><strong>No expense history yet</strong><p>Your monthly spending trend will be drawn here once you record expenses.</p></div>`;
    return;
  }
  const scale = niceMax(Math.max(...buckets.map((b) => b.expense), 1));
  const base = 210, top = 20, span = base - top;
  const step = buckets.length > 1 ? 860 / (buckets.length - 1) : 0;
  const points = buckets.map((b, i) => ({ x: 20 + step * i, y: base - (b.expense / scale) * span, b }));
  const line = points.map((p) => `${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(' ');
  const area = `M ${points[0].x.toFixed(1)},${base} L ${line} L ${points[points.length - 1].x.toFixed(1)},${base} Z`;
  let grids = '';
  for (const f of [1, 0.75, 0.5, 0.25]) {
    const y = (base - f * span).toFixed(1);
    grids += `<line class="cf-grid" x1="16" x2="890" y1="${y}" y2="${y}"/>`;
  }
  const dots = points.map((p, i) => `<circle class="trend-dot" data-i="${i}" cx="${p.x.toFixed(1)}" cy="${p.y.toFixed(1)}" r="4"><title>${monthLabel(p.b.key)}: ${fmtMoney(p.b.expense)}</title></circle>`).join('');
  const labels = points.map((p) => `<text class="cf-xlabel" x="${p.x.toFixed(1)}" y="232" text-anchor="middle">${monthLabel(p.b.key, 'short')}</text>`).join('');
  const yAxis = [1, 0.75, 0.5, 0.25, 0].map((f) => `<span>${f === 0 ? '0' : fmtCompact(scale * f)}</span>`).join('');
  mount.innerHTML = `
    <div class="chart-frame"><div class="cf-yaxis">${yAxis}</div>
      <svg class="cf-svg" viewBox="0 0 900 240" role="img" aria-label="Monthly expense trend">${grids}
        <path class="trend-area" d="${area}"/><path class="trend-line" d="M ${line}"/>${dots}${labels}
      </svg><div class="chart-tip" hidden></div>
    </div>`;
  const tip = mount.querySelector('.chart-tip');
  const svg = mount.querySelector('svg');
  mount.querySelectorAll('.trend-dot').forEach((dot) => {
    const i = Number(dot.dataset.i);
    const bucket = buckets[i];
    dot.addEventListener('mouseenter', () => {
      const prev = buckets[i - 1];
      let vs = 'No previous month';
      if (prev && prev.expense) {
        const pct = ((bucket.expense - prev.expense) / prev.expense) * 100;
        vs = (pct >= 0 ? '+' : '−') + Math.abs(pct).toFixed(1) + '% vs previous';
      }
      tip.innerHTML = `<b>${monthLabel(bucket.key)}</b><div class="tip-row"><i class="dot exp"></i>Expenses<strong>${fmtMoney(bucket.expense)}</strong></div><div class="tip-row net">${vs}</div>`;
      tip.hidden = false;
      const svgBox = svg.getBoundingClientRect();
      const mountBox = mount.getBoundingClientRect();
      const scaleX = svgBox.width / 900;
      const left = svgBox.left - mountBox.left + points[i].x * scaleX;
      tip.style.left = Math.max(6, Math.min(mountBox.width - tip.offsetWidth - 6, left - tip.offsetWidth / 2)) + 'px';
      tip.style.top = Math.max(4, (svgBox.top - mountBox.top) + points[i].y * (svgBox.height / 240) - tip.offsetHeight - 12) + 'px';
    });
    dot.addEventListener('mouseleave', () => { tip.hidden = true; });
  });
}

function renderDonut() {
  const mount = $('catChart');
  if (!mount) return;
  const cats = state.analytics.categories || [];
  const total = cats.reduce((sum, c) => sum + (Number(c.amount_minor) || 0), 0);
  $('catTotalSub').textContent = cats.length
    ? `${fmtMoney(total)} ${t('across', { n: cats.length })}`
    : t('all_recorded');
  if (!cats.length) {
    mount.innerHTML = `<div class="empty"><span class="empty-icon">${icon('i-pie')}</span><strong>No expenses yet</strong><p>Record a few expenses to see your category breakdown.</p></div>`;
    return;
  }
  const C = 2 * Math.PI * 78;
  let acc = 0;
  const arcs = cats.map((c) => {
    const share = Math.max(0, Math.min(1, Number(c.share) || (c.amount_minor / total)));
    const len = Math.max(share * C - 2, 0);
    const arc = `<circle class="donut-arc" cx="100" cy="100" r="78" style="stroke:${catMeta(c.category).color};stroke-dasharray:${len.toFixed(2)} ${(C - len).toFixed(2)};stroke-dashoffset:${(-acc * C).toFixed(2)}"/>`;
    acc += share;
    return arc;
  }).join('');
  const rows = cats.map((c) => {
    const pct = Math.round((Number(c.share) || 0) * 100);
    return `<div class="legend-row"><i class="dot" style="background:${catMeta(c.category).color}"></i><span>${esc(catLabelT(c.category))}</span><strong>${fmtMoney(c.amount_minor)}</strong><small>${pct}%</small></div>`;
  }).join('');
  mount.innerHTML = `
    <div class="category-chart">
      <div class="donut-wrap"><svg class="donut-svg" viewBox="0 0 200 200" role="img" aria-label="Expenses by category"><circle class="donut-track" cx="100" cy="100" r="78"/>${arcs}</svg>
        <div class="donut-center"><strong>${fmtCompact(total)}</strong><small>${t('donut_total')}</small></div>
      </div>
      <div class="legend-list">${rows}</div>
    </div>`;
}

/* ---------- 9. Overview page ---------- */
function statCard({ label, iconName, iconCls, value, valueIsText, footHTML, barsHTML, dark, heroChips }) {
  return `
    <article class="stat-card${dark ? ' balance-card' : ''}">
      <div class="stat-top"><span>${esc(label)}</span><span class="stat-top-right">${dark
        ? `<button type="button" class="eye-btn" data-privacy aria-label="${t('hide_amounts')}" title="${t('hide_amounts')}">${icon('i-eye', 'icon sm')}</button>
        <button type="button" class="eye-btn" data-open-tx aria-label="${t('btn_add_tx')}" title="${t('btn_add_tx')}">${icon('i-wallet', 'icon sm')}</button>`
        : `<span class="card-icon ${iconCls}">${icon(iconName, 'icon sm')}</span>`}</span></div>
      <div class="amount"${Number.isFinite(value) ? ` data-count="${value}"` : ''}>${valueIsText ? esc(value) : fmtMoney(value)}</div>
      <div class="stat-foot">${footHTML}</div>
      ${dark && heroChips ? `<div class="hero-chips">${heroChips}</div>` : ''}
      ${barsHTML || ''}
      ${dark ? '<div class="balance-decoration"></div>' : ''}
    </article>`;
}

function sparkBars(values, expense) {
  const max = Math.max(...values, 1);
  return `<div class="mini-bars${expense ? ' expense-bars' : ''}">` +
    values.map((v) => `<i style="height:${Math.max(12, Math.round((v / max) * 100))}%"></i>`).join('') + '</div>';
}

function renderGreeting() {
  const hour = new Date().getHours();
  const part = hour < 12 ? 'morning' : hour < 18 ? 'afternoon' : 'evening';
  const greeting = $('greeting');
  if (greeting) {
    const greetKey = hour < 12 ? 'greet_morning' : hour < 18 ? 'greet_afternoon' : 'greet_evening';
    greeting.innerHTML = `${t(greetKey)}, <strong>${esc(displayName() || 'there')}</strong>`;
  }
}

function renderStatGrid() {
  const mount = $('statGrid');
  if (!mount) return;
  const s = state.summary;
  const buckets = monthBuckets(2);
  const current = buckets[1], previous = buckets[0];

  const netMonth = s.month_income_minor - s.month_expense_minor;
  const netTrend = netMonth > 0
    ? `<span class="trend up">${icon('i-trend-up', 'icon xs')}+${fmtMoney(netMonth)}</span>`
    : netMonth < 0
      ? `<span class="trend down">${icon('i-trend-down', 'icon xs')}−${fmtMoney(Math.abs(netMonth))}</span>`
      : `<span class="trend flat">${t('no_change')}</span>`;

  const incomeTrend = trendOf(current.income, previous.income);
  const expenseTrend = trendOf(current.expense, previous.expense);
  const expenseCls = expenseTrend.cls === 'up' ? 'down' : expenseTrend.cls === 'down' ? 'up' : 'flat';
  const expenseIconName = expenseTrend.cls === 'up' ? 'i-trend-up' : expenseTrend.cls === 'down' ? 'i-trend-down' : 'i-swap';

  const eight = monthBuckets(8);
  mount.innerHTML =
    statCard({
      label: t('card_balance'), iconName: 'i-wallet', iconCls: 'dark-icon', dark: true,
      value: s.balance_minor,
      footHTML: netTrend + `<span>${t('this_month')}</span><span>${s.transaction_count} ${t('tx_word')}</span>`,
      heroChips:
        `<span class="hero-chip">${icon('i-arrow-in')}${t('card_income')} <b>+${fmtMoney(s.month_income_minor)}</b></span>`
        + `<span class="hero-chip">${icon('i-arrow-out')}${t('card_expenses')} <b>−${fmtMoney(s.month_expense_minor)}</b></span>`,
    }) +
    statCard({
      label: `${t('tx_income_m')} · ${monthLabel(current.key, 'short')}`, iconName: 'i-arrow-in', iconCls: 'income-icon',
      value: s.month_income_minor,
      footHTML: `<span class="trend ${incomeTrend.cls}">${icon(incomeTrend.cls === 'down' ? 'i-trend-down' : 'i-trend-up', 'icon xs')}${incomeTrend.text}</span><span>${t('vs_last')}</span>`,
      barsHTML: sparkBars(eight.map((b) => b.income)),
    }) +
    statCard({
      label: `${t('tx_expenses_m')} · ${monthLabel(current.key, 'short')}`, iconName: 'i-arrow-out', iconCls: 'expense-icon',
      value: s.month_expense_minor,
      footHTML: `<span class="trend ${expenseCls}">${icon(expenseIconName, 'icon xs')}${expenseTrend.text}</span><span>${t('vs_last')}</span>`,
      barsHTML: sparkBars(eight.map((b) => b.expense), true),
    });
  animateAmounts(mount);
}

function renderBudgetSnapshot() {
  const mount = $('budgetSnapshot');
  if (!mount) return;
  const budgets = state.analytics.budgets || [];
  const spent = state.summary.month_expense_minor;
  const star = budgets.find((b) => b.category === '*');
  const limit = star ? star.amount_minor : budgets.reduce((sum, b) => sum + b.amount_minor, 0);

  if (!budgets.length) {
    mount.innerHTML = `
      <div class="budget-total"><div><span class="muted">${t('spent_this_month')}</span><strong>${fmtMoney(spent)}</strong></div></div>
      <div class="budget-foot"><span>${t('no_budget_note')}</span></div>
      <button class="full-link" data-page="planning">${t('manage_budgets')} ${icon('i-chev-right', 'icon xs')}</button>`;
    return;
  }
  const pct = percentOf(spent, limit);
  const cls = progressClass(pct);
  const top = budgets
    .filter((b) => b.category !== '*')
    .sort((a, b) => b.spent_minor - a.spent_minor)
    .slice(0, 3)
    .map((b) => {
      const p = percentOf(b.spent_minor, b.amount_minor);
      return `<div class="cat-row"><span class="cat-icon ${catClass(b.category)}">${icon(catMeta(b.category).icon, 'icon sm')}</span>
        <div class="cat-copy"><strong>${esc(catLabelT(b.category))}</strong><small>${fmtMoney(b.spent_minor)} ${t('spent')} ${t('of')} ${fmtMoney(b.amount_minor)}</small>
        <div class="progress thin"><span class="${progressClass(p)}" style="width:${Math.min(100, p)}%"></span></div></div>
        <span class="cat-pct ${progressClass(p)}">${p}%</span></div>`;
    }).join('');
  mount.innerHTML = `
    <div class="budget-total"><div><span class="muted">${t('spent_this_month')}</span><strong>${fmtMoney(spent)}</strong></div><span class="percent ${cls}">${pct}%</span></div>
    <div class="progress"><span class="${cls}" style="width:${Math.min(100, pct)}%"></span></div>
    <div class="budget-foot"><span>${fmtMoney(spent)} ${t('spent')}</span><span>${fmtMoney(limit)} ${t('limit')}</span></div>
    ${spent > limit ? `<small class="over-note" style="margin-top:6px">${t('over_by', { x: fmtMoney(spent - limit) })}</small>` : ''}
    <div class="divider"></div>
    ${top || ''}
    <button class="full-link" data-page="planning">Manage budgets ${icon('i-chev-right', 'icon xs')}</button>`;
}

function txName(t) {
  return t.description || t.category || 'Transaction';
}

function renderRecent() {
  const mount = $('recentRows');
  if (!mount) return;
  const recent = state.transactions.slice(0, 5);
  if (!recent.length) {
    mount.innerHTML = `<tr><td colspan="4"><div class="empty"><span class="empty-icon">${icon('i-swap')}</span><strong>No transactions yet</strong><p>Add your first income or expense to see it here.</p><button class="btn soft" data-open-tx>${icon('i-plus', 'icon sm')} Add transaction</button></div></td></tr>`;
    return;
  }
  mount.innerHTML = recent.map((tx) => {
    const income = tx.kind === 'income';
    return `<tr>
      <td><div class="tx-cell"><span class="tx-icon ${catClass(tx.category)}">${icon(catMeta(tx.category).icon, 'icon sm')}</span><div class="tx-copy"><strong>${esc(txName(tx))}</strong></div></div></td>
      <td><span class="pill ${catClass(tx.category)}">${esc(catLabelT(tx.category))}</span></td>
      <td class="muted-cell">${fmtDate(tx.created_at)}</td>
      <td class="amount-cell ${income ? 'in' : 'out'}">${income ? '+' : '−'}${fmtMoney(tx.amount_minor)}</td>
    </tr>`;
  }).join('');
}

function renderOverviewGoals() {
  const mount = $('overviewGoals');
  if (!mount) return;
  const goals = state.goals.slice(0, 4);
  if (!goals.length) {
    mount.innerHTML = `<div class="empty"><span class="empty-icon">${icon('i-target')}</span><strong>${t('no_goals_ov')}</strong><p>${t('no_goals_ov_t')}</p><button class="btn soft" data-open-goal>${icon('i-plus', 'icon sm')} ${t('new_goal_btn')}</button></div>`;
    return;
  }
  mount.innerHTML = `<div class="goal-carousel">` + goals.map((g) => {
    const pct = percentOf(g.saved_minor, g.target_minor);
    const done = g.saved_minor >= g.target_minor;
    return `<div class="goal-card${done ? ' goal-done' : ''}">
      <div class="goal-head"><span class="goal-ring">${ringSvg(pct)}</span>
        <div class="goal-copy"><strong>${esc(g.name)}</strong><small>${t('target', { x: fmtMoney(g.target_minor) })}</small></div></div>
      <div class="goal-big">${fmtMoney(g.saved_minor)} <small>/ ${fmtMoney(g.target_minor)}</small></div>
      <div class="progress"><span class="${progressClass(pct)}" style="width:${Math.min(100, pct)}%"></span></div>
      <div class="goal-foot"><span>${t('funded', { p: pct })}</span><span>${done ? t('goal_reached') : t('to_go', { x: fmtMoney(g.target_minor - g.saved_minor) })}</span></div>
    </div>`;
  }).join('') + '</div>';
}

/* ---------- 10. Transactions page ---------- */
function renderTxStats() {
  const mount = $('txStats');
  if (!mount) return;
  const s = state.summary;
  const buckets = monthBuckets(2);
  const current = buckets[1], previous = buckets[0];
  const incomeTrend = trendOf(current.income, previous.income);
  const expenseTrend = trendOf(current.expense, previous.expense);
  const expenseCls = expenseTrend.cls === 'up' ? 'down' : expenseTrend.cls === 'down' ? 'up' : 'flat';
  const cats = new Set(state.transactions.map((t) => t.category));
  mount.innerHTML =
    statCard({
      label: `${t('tx_income_m')} · ${monthLabel(current.key, 'short')}`, iconName: 'i-arrow-in', iconCls: 'income-icon',
      value: s.month_income_minor,
      footHTML: `<span class="trend ${incomeTrend.cls}">${icon(incomeTrend.cls === 'down' ? 'i-trend-down' : 'i-trend-up', 'icon xs')}${incomeTrend.text}</span><span>${t('vs_last')}</span>`,
    }) +
    statCard({
      label: `${t('tx_expenses_m')} · ${monthLabel(current.key, 'short')}`, iconName: 'i-arrow-out', iconCls: 'expense-icon',
      value: s.month_expense_minor,
      footHTML: `<span class="trend ${expenseCls}">${icon(expenseTrend.cls === 'up' ? 'i-trend-up' : expenseTrend.cls === 'down' ? 'i-trend-down' : 'i-swap', 'icon xs')}${expenseTrend.text}</span><span>${t('vs_last')}</span>`,
    }) +
    statCard({
      label: t('tx_count_card'), iconName: 'i-swap', iconCls: '',
      value: String(s.transaction_count), valueIsText: true,
      footHTML: `<span>${t('across', { n: cats.size })}</span>`,
    });
  animateAmounts(mount);
}

function dayLabel(iso) {
  const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
  if (iso === todayISO()) return t('today');
  if (iso === yesterday) return t('yesterday');
  return fmtDate(iso);
}

function filteredTransactions() {
  const f = state.filters;
  const q = f.q.trim().toLowerCase();
  let list = state.transactions.filter((t) => {
    if (f.type !== 'all' && t.kind !== f.type) return false;
    if (f.category !== 'all' && t.category !== f.category) return false;
    if (f.month !== 'all' && String(t.created_at).slice(0, 7) !== f.month) return false;
    if (q) {
      const hay = `${t.description || ''} ${t.category} ${t.kind} ${String(t.created_at).slice(0, 10)}`.toLowerCase();
      if (!hay.includes(q)) return false;
    }
    return true;
  });
  return list;
}

function renderTxFilters() {
  const catSelect = $('categoryFilter');
  const monthSelect = $('monthFilter');
  if (catSelect) {
    const categories = [...new Set(state.transactions.map((t) => t.category))].sort();
    const keep = state.filters.category;
    catSelect.innerHTML = `<option value="all">${t('all_categories')}</option>` +
      categories.map((c) => `<option value="${esc(c)}">${esc(c)}</option>`).join('');
    if ([...catSelect.options].some((o) => o.value === keep)) catSelect.value = keep;
    else { catSelect.value = 'all'; state.filters.category = 'all'; }
  }
  if (monthSelect) {
    const months = [...new Set(state.transactions.map((t) => String(t.created_at).slice(0, 7)))].sort().reverse();
    const keep = state.filters.month;
    monthSelect.innerHTML = `<option value="all">${t('all_months')}</option>` +
      months.map((m) => `<option value="${m}">${monthLabel(m)}</option>`).join('');
    if ([...monthSelect.options].some((o) => o.value === keep)) monthSelect.value = keep;
    else { monthSelect.value = 'all'; state.filters.month = 'all'; }
  }
}

function renderTxTable() {
  const tbody = $('allRows');
  if (!tbody) return;
  const list = filteredTransactions();
  const pages = Math.max(1, Math.ceil(list.length / PAGE_SIZE));
  state.filters.page = Math.min(state.filters.page, pages);
  const start = (state.filters.page - 1) * PAGE_SIZE;
  const pageItems = list.slice(start, start + PAGE_SIZE);

  if (!pageItems.length) {
    const anyData = state.transactions.length > 0;
    tbody.innerHTML = `<tr><td colspan="6"><div class="empty"><span class="empty-icon">${icon('i-search')}</span><strong>${anyData ? t('nothing_found') : t('no_tx_yet')}</strong><p>${anyData ? t('try_another') : t('no_tx_yet_t')}</p>${anyData ? '' : `<button class="btn soft" data-open-tx>${icon('i-plus', 'icon sm')} ${t('btn_add_tx')}</button>`}</div></td></tr>`;
  } else {
    let lastDay = null;
    tbody.innerHTML = pageItems.map((tx) => {
      const income = tx.kind === 'income';
      const day = String(tx.created_at).slice(0, 10);
      const dayHeader = day !== lastDay
        ? `<tr class="day-row"><td colspan="6">${esc(dayLabel(day))}</td></tr>`
        : '';
      lastDay = day;
      return `${dayHeader}<tr>
        <td><div class="tx-cell"><span class="tx-icon ${catClass(tx.category)}">${icon(catMeta(tx.category).icon, 'icon sm')}</span><div class="tx-copy"><strong>${esc(txName(tx))}</strong></div></div></td>
        <td><span class="pill ${catClass(tx.category)}">${esc(catLabelT(tx.category))}</span></td>
        <td class="muted-cell">${fmtDate(tx.created_at)}</td>
        <td><span class="type-pill ${income ? 'income' : 'expense'}">${income ? t('type_income') : t('type_expense')}</span></td>
        <td class="amount-cell ${income ? 'in' : 'out'}">${income ? '+' : '−'}${fmtMoney(tx.amount_minor)}</td>
        <td class="row-actions"><button class="icon-ghost" data-del-tx="${tx.id}" title="Delete transaction" aria-label="Delete transaction">${icon('i-trash', 'icon sm')}</button></td>
      </tr>`;
    }).join('');
  }

  const showing = $('showingCount');
  if (showing) {
    showing.textContent = list.length
      ? t('showing', { a: start + 1, b: Math.min(start + PAGE_SIZE, list.length), n: list.length })
      : t('no_tx_list');
  }
  renderPager(list.length, pages);
}

function renderPager(total, pages) {
  const pager = $('pager');
  if (!pager) return;
  if (pages <= 1) { pager.innerHTML = total ? `<span class="pager-info">Page 1 of 1</span>` : ''; return; }
  const current = state.filters.page;
  let start = Math.max(1, current - 2);
  const end = Math.min(pages, start + 4);
  start = Math.max(1, end - 4);
  let html = `<button class="page-btn" data-page-go="${current - 1}" ${current === 1 ? 'disabled' : ''} aria-label="Previous page">${icon('i-chev-left', 'icon xs')}</button>`;
  for (let p = start; p <= end; p++) {
    html += `<button class="page-btn${p === current ? ' active' : ''}" data-page-go="${p}">${p}</button>`;
  }
  html += `<button class="page-btn" data-page-go="${current + 1}" ${current === pages ? 'disabled' : ''} aria-label="Next page">${icon('i-chev-right', 'icon xs')}</button>`;
  pager.innerHTML = html;
}

/* ---------- 11. Insights page ---------- */
function renderInsightStats() {
  const mount = $('insightStats');
  if (!mount) return;
  const s = state.summary;
  const currentBucket = monthBuckets(1)[0];
  const dayOfMonth = new Date().getDate();
  const avgDaily = Math.round(currentBucket.expense / Math.max(1, dayOfMonth));
  const cats = state.analytics.categories || [];
  const top = cats[0];
  const forecast = state.analytics.forecast || {};
  const forecastOk = forecast.status === 'ok';

  mount.innerHTML =
    statCard({
      label: t('avg_daily'), iconName: 'i-clock', iconCls: '',
      value: avgDaily,
      footHTML: `<span>${t('based_on', { d: dayOfMonth, m: monthLabel(currentBucket.key, 'short') })}</span>`,
    }) +
    statCard({
      label: t('top_category'),
      iconName: top ? catMeta(top.category).icon : 'i-tag',
      iconCls: top ? catClass(top.category) : '',
      value: top ? top.category : '—', valueIsText: true,
      footHTML: top ? `<span>${t('of_all', { p: Math.round((top.share || 0) * 100) })}</span>` : `<span>${t('no_exp_rec')}</span>`,
    }) +
    statCard({
      label: t('forecast_card', { m: monthLabel(shiftMonth(currentMonthKey(), 1), 'short') }), iconName: 'i-trend-up', iconCls: 'gold',
      value: forecastOk ? forecast.forecast_minor : 0,
      valueIsText: !forecastOk,
      footHTML: forecastOk
        ? `<span class="trend flat">${t('mean3')}</span>`
        : `<span>${esc(forecast.message || 'Not enough history yet.')}</span>`,
    });
  animateAmounts(mount);
}

function renderObservations() {
  const mount = $('observations');
  if (!mount) return;
  const tips = [];
  for (const b of state.analytics.budgets || []) {
    if (b.over_budget) {
      tips.push({
        variant: 'red', icon: 'i-alert',
        title: t('obs_over_t', { c: catLabelT(b.category) }),
        text: t('obs_over_d', { s: fmtMoney(b.spent_minor), l: fmtMoney(b.amount_minor), m: monthLabel(b.month) }),
      });
    }
  }
  const top = (state.analytics.categories || [])[0];
  if (top) {
    tips.push({
      variant: 'gold', icon: 'i-tag',
      title: t('obs_top_t', { c: catLabelT(top.category) }),
      text: t('obs_top_d', { p: Math.round((top.share || 0) * 100) }),
    });
  }
  const forecast = state.analytics.forecast || {};
  if (forecast.status === 'ok') {
    tips.push({
      variant: 'purple', icon: 'i-trend-up',
      title: t('obs_fc_t'),
      text: t('obs_fc_d', { x: fmtMoney(forecast.forecast_minor), m: monthLabel(forecast.forecast_month) }),
    });
  }
  const activeGoals = state.goals.filter((g) => g.saved_minor < g.target_minor);
  if (activeGoals.length) {
    const remaining = activeGoals.reduce((sum, g) => sum + (g.target_minor - g.saved_minor), 0);
    tips.push({
      variant: 'green', icon: 'i-target',
      title: t('obs_goals_t'),
      text: t('obs_goals_d', { x: fmtMoney(remaining), w: activeGoals.length === 1 ? t('goal_one') : t('goals_word') }),
    });
  }
  if (!tips.length) {
    mount.innerHTML = `<div class="empty"><span class="empty-icon">${icon('i-spark')}</span><strong>${t('obs_none_t')}</strong><p>${t('obs_none_d')}</p></div>`;
    return;
  }
  mount.innerHTML = tips.slice(0, 4).map((tip) =>
    `<div class="obs-tip"><span class="tip-icon ${tip.variant}">${icon(tip.icon)}</span><div><strong>${esc(tip.title)}</strong><p>${esc(tip.text)}</p></div></div>`
  ).join('') + `<p class="disclaimer">${t('disclaimer')}</p>`;
}

/* ---------- 12. Planning page ---------- */
function renderPlanningMonth() {
  const label = $('planningMonth');
  if (label) label.textContent = monthLabel(state.planMonth);
}

function renderPlanningSummary() {
  const mount = $('planningSummary');
  if (!mount) return;
  const rows = state.budgets;
  const star = rows.find((r) => r.category === '*');
  const limit = star ? star.amount_minor : rows.reduce((sum, r) => sum + r.amount_minor, 0);
  const spent = star ? star.spent_minor : bucketFor(state.planMonth).expense;
  const pct = percentOf(spent, limit);
  const cls = progressClass(pct);
  const saved = state.goals.reduce((sum, g) => sum + g.saved_minor, 0);
  mount.innerHTML = `
    <div class="ps-cell"><span class="ps-label">${rows.length ? t('budget_used') : t('spent_this_month')}</span>
      <strong>${fmtMoney(spent)}</strong>
      <small>${rows.length ? t('budget_of', { x: fmtMoney(limit) }) : `${t('in_month', { m: monthLabel(state.planMonth) })} — ${t('no_budgets_yet')}`}</small></div>
    <div class="ps-progress"><div class="progress"><span class="${cls}" style="width:${Math.min(100, pct)}%"></span></div><span>${rows.length ? t('of_monthly_limit', { p: pct }) : t('no_budget_note')}</span></div>
    <div class="ps-cell"><span class="ps-label">${t('saved_toward', { x: fmtMoney(saved) })}</span><strong>${fmtMoney(saved)}</strong><small>${LANG === 'ru' && state.goals.length === 1 ? 'в 1 цели' : t('across_goals', { n: state.goals.length })}</small></div>`;
}

function renderBudgetsList() {
  const mount = $('budgetsList');
  if (!mount) return;
  if (!state.budgets.length) {
    mount.innerHTML = `<div class="empty"><span class="empty-icon">${icon('i-wallet')}</span><strong>${t('no_budget_for', { m: monthLabel(state.planMonth) })}</strong><p>${t('no_budget_note')}</p><button class="btn soft" data-open-budget>${icon('i-plus', 'icon sm')} ${t('new_budget')}</button></div>`;
    return;
  }
  const sorted = [...state.budgets].sort((a, b) => (a.category === '*' ? -1 : b.category === '*' ? 1 : a.category.localeCompare(b.category)));
  mount.innerHTML = sorted.map((b) => {
    const pct = percentOf(b.spent_minor, b.amount_minor);
    const cls = progressClass(pct);
    return `<div class="plan-row">
      <span class="cat-icon ${b.category === '*' ? 'cat-other' : catClass(b.category)}">${icon(catMeta(b.category).icon, 'icon sm')}</span>
      <div class="plan-copy"><strong>${esc(catLabelT(b.category))}</strong><small>${t('spent_of', { a: fmtMoney(b.spent_minor), b: fmtMoney(b.amount_minor) })}</small>
        <div class="progress"><span class="${cls}" style="width:${Math.min(100, pct)}%"></span></div>
        ${b.over_budget ? `<small class="over-note">${t('over_by', { x: fmtMoney(b.spent_minor - b.amount_minor) })}</small>` : ''}</div>
      <div class="plan-meta"><strong class="${cls}">${pct}%</strong><small>${t('remaining', { x: fmtMoney(Math.max(0, b.remaining_minor)) })}</small></div>
      <div class="row-actions">
        <button class="icon-ghost" data-edit-budget="${b.id}" title="${t('m_budget_edit')}" aria-label="${t('m_budget_edit')}">${icon('i-edit', 'icon sm')}</button>
        <button class="icon-ghost danger" data-del-budget="${b.id}" title="${t('conf_del_budget')}" aria-label="${t('conf_del_budget')}">${icon('i-trash', 'icon sm')}</button>
      </div></div>`;
  }).join('');
}

function renderGoalsGrid() {
  const mount = $('goalsGrid');
  if (!mount) return;
  if (!state.goals.length) {
    mount.innerHTML = `<div class="empty" style="grid-column:1/-1"><span class="empty-icon">${icon('i-target')}</span><strong>${t('no_goals_ov')}</strong><p>${t('no_goals_ov_t')}</p><button class="btn soft" data-open-goal>${icon('i-plus', 'icon sm')} ${t('new_goal_btn')}</button></div>`;
    return;
  }
  mount.innerHTML = state.goals.map((g) => {
    const pct = percentOf(g.saved_minor, g.target_minor);
    const done = g.saved_minor >= g.target_minor;
    return `<div class="goal-card${done ? ' goal-done' : ''}">
      <div class="goal-head"><span class="goal-ring">${ringSvg(pct)}</span>
        <div class="goal-copy"><strong>${esc(g.name)}</strong><small>${t('target', { x: fmtMoney(g.target_minor) })}</small></div>
        ${done ? `<span class="goal-done-badge">${icon('i-check', 'icon xs')} Complete</span>` : ''}
        <div class="row-actions">
          <button class="icon-ghost" data-edit-goal="${g.id}" title="${t('update_progress')}" aria-label="${t('update_progress')}">${icon('i-edit', 'icon sm')}</button>
          <button class="icon-ghost danger" data-del-goal="${g.id}" title="${t('conf_del_goal')}" aria-label="${t('conf_del_goal')}">${icon('i-trash', 'icon sm')}</button>
        </div></div>
      <div class="goal-big">${fmtMoney(g.saved_minor)} <small>/ ${fmtMoney(g.target_minor)}</small></div>
      <div class="progress"><span class="${progressClass(pct)}" style="width:${Math.min(100, pct)}%"></span></div>
      <div class="goal-foot"><span>${t('funded', { p: pct })}</span><span>${done ? t('goal_reached') : t('to_go', { x: fmtMoney(g.target_minor - g.saved_minor) })}</span></div>
      <button class="btn soft full" data-topup="${g.id}">${icon('i-plus', 'icon sm')} ${t('add_funds')}</button>
    </div>`;
  }).join('');
}

/* ---------- 13. Profile & chrome ---------- */
function displayName() {
  return state.settings.displayName || state.user?.username || '';
}

function renderProfile() {
  const name = displayName();
  const avatar = $('avatar');
  if (avatar) avatar.textContent = initials(name);
  const avatarTop = $('avatarTop');
  if (avatarTop) avatarTop.textContent = initials(name);
  const profileName = $('profileName');
  if (profileName) profileName.textContent = name;
  const profileSub = $('profileSub');
  if (profileSub) profileSub.textContent = '@' + (state.user?.username || '');
}

function renderChips() {
  const insight = $('insightChip');
  if (insight) insight.querySelector('span').textContent = monthLabel(currentMonthKey()) + ' · ' + t('ins_chip_all');
}

/* ---------- 14. Add-transaction modal ---------- */
function categoryOptions(kind, selected) {
  const list = kind === 'income' ? INCOME_CATEGORIES : EXPENSE_CATEGORIES;
  return list.map((c) => `<option value="${esc(c)}"${c === selected ? ' selected' : ''}>${esc(catLabelT(c))}</option>`).join('');
}

function openTxModal() {
  const modal = openModal(`
    <div class="modal-head"><div><div class="eyebrow">${t('m_quick')}</div><h2>${t('m_tx_t')}</h2></div>
      <button type="button" class="icon-ghost" data-close aria-label="Close">${icon('i-x', 'icon sm')}</button></div>
    <form id="txForm" novalidate>
      <div class="type-toggle" id="m-toggle">
        <button type="button" class="type-option selected" data-kind="expense">${t('m_expense')}</button>
        <button type="button" class="type-option" data-kind="income">${t('m_income_p')}</button>
      </div>
      <label class="field-label">${t('m_amount_kzt')}
        <div class="amount-input"><span>₸</span><input id="m-amount" type="number" min="0.01" step="0.01" placeholder="0" required></div>
      </label>
      <div class="form-row">
        <label class="field-label">${t('m_category')}<select id="m-category">${categoryOptions('expense')}</select></label>
        <label class="field-label">${t('m_date')}<input id="m-date" type="date" required></label>
      </div>
      <label class="field-label">${t('m_desc')}
        <div class="input-wrap">${icon('i-tag', 'icon sm')}<input id="m-desc" type="text" maxlength="200" placeholder="${t('m_desc_ph')}" required></div>
      </label>
      <div class="suggest-row">
        <button type="button" class="btn soft sm" id="m-suggest">${icon('i-spark', 'icon xs')} ${t('suggest')}</button>
        <button type="button" class="btn soft sm" id="m-qr">${icon('i-qr', 'icon xs')} ${t('scan_qr')}</button>
      </div>
      <div class="ai-hint" id="m-aihint" hidden></div>
      <div class="form-alert" id="m-alert" hidden></div>
      <div class="modal-actions">
        <button type="button" class="btn ghost" data-close>${t('m_cancel')}</button>
        <button type="submit" class="btn primary" id="m-save">${t('save_tx')}</button>
      </div>
    </form>`, { narrow: true });

  const box = modal.box;
  const dateInput = box.querySelector('#m-date');
  dateInput.value = todayISO();
  dateInput.max = todayISO();
  let kind = 'expense';

  box.querySelectorAll('#m-toggle .type-option').forEach((btn) => {
    btn.addEventListener('click', () => {
      box.querySelectorAll('#m-toggle .type-option').forEach((b) => b.classList.toggle('selected', b === btn));
      kind = btn.dataset.kind;
      box.querySelector('#m-category').innerHTML = categoryOptions(kind);
    });
  });

  const hint = box.querySelector('#m-aihint');
  function showHint(text, ok = true) {
    hint.hidden = false;
    hint.innerHTML = icon('i-spark', 'icon') + '<span>' + esc(text) + '</span>';
    hint.style.color = ok ? '' : 'var(--muted)';
  }
  box.querySelector('#m-suggest').addEventListener('click', async () => {
    const description = box.querySelector('#m-desc').value.trim();
    if (kind !== 'expense') { showHint('Category suggestions work for expenses.', false); return; }
    if (description.length < 3) { showHint('Type a description first — at least a few words.', false); return; }
    hint.hidden = true;
    try {
      const result = await request('/analytics/classify', { method: 'POST', body: JSON.stringify({ description }) });
      if (result.category && EXPENSE_CATEGORIES.includes(result.category)) {
        box.querySelector('#m-category').value = result.category;
        showHint(`Suggested “${result.category}” — ${Math.round((result.confidence || 0) * 100)}% confidence`);
      } else {
        showHint(result.message || 'No familiar terms found — choose a category manually.', false);
      }
    } catch (err) {
      showHint(err.message || 'Suggestions are unavailable right now.', false);
    }
  });

  box.querySelector('#m-qr').addEventListener('click', () => {
    openQrModal((text) => {
      const desc = box.querySelector('#m-desc');
      if (desc && !desc.value.trim()) desc.value = String(text).slice(0, 200);
      toast(t('toast_qr'), 'info');
    });
  });

  function fail(message) {
    const alert = box.querySelector('#m-alert');
    alert.hidden = false;
    alert.textContent = message;
  }
  box.querySelector('#txForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const amount = Number(box.querySelector('#m-amount').value);
    const description = box.querySelector('#m-desc').value.trim();
    const category = box.querySelector('#m-category').value;
    const date = dateInput.value;
    if (!Number.isFinite(amount) || amount <= 0) return fail('Enter an amount greater than zero.');
    if (!description) return fail('Add a short description.');
    if (category === '*') return fail('Choose a concrete category.');
    const saveBtn = box.querySelector('#m-save');
    saveBtn.disabled = true;
    try {
      await api('/transactions', {
        method: 'POST',
        body: JSON.stringify({ kind, amount_minor: Math.round(amount * 100), category, description, date }),
      });
      modal.close();
      toast(t('toast_saved'));
      await loadAll();
    } catch (err) {
      if (!err.handled) fail(err.message);
      saveBtn.disabled = false;
    }
  });
}

/* ---------- 14b. QR scanner (camera + native/jsQR decoder) ---------- */
function openQrModal(onResult) {
  const modal = openModal(`
    <div class="modal-head"><div><div class="eyebrow">Scanner</div><h2>Scan QR code</h2></div>
      <button type="button" class="icon-ghost" data-close aria-label="Close">${icon('i-x', 'icon sm')}</button></div>
    <div class="qr-stage">
      <video id="qr-video" playsinline muted></video>
      <div class="qr-frame"></div>
    </div>
    <div class="field-hint" id="qr-status" role="status" aria-live="polite">${t('qr_status')}</div>
    <div class="modal-actions">
      <button type="button" class="btn ghost" data-close>Close</button>
    </div>`, {
    narrow: true,
    rootId: 'qrRoot',
    onClose: () => cleanup(),
  });

  const box = modal.box;
  const video = box.querySelector('#qr-video');
  const status = box.querySelector('#qr-status');
  let stream = null;
  let timer = null;
  let settled = false;

  function cleanup() {
    if (timer) { clearInterval(timer); timer = null; }
    if (stream) { stream.getTracks().forEach((t) => t.stop()); stream = null; }
  }
  function statusMessage(text, type = '') {
    status.textContent = text;
    status.className = 'field-hint' + (type ? ' ' + type : '');
  }

  if (!navigator.mediaDevices?.getUserMedia) {
    statusMessage(t('qr_fallback_context'), 'error');
    return;
  }

  (async () => {
    try {
      stream = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: {
          facingMode: { ideal: 'environment' },
          width: { ideal: 1280 },
          height: { ideal: 720 },
        },
      });
      video.srcObject = stream;
      await video.play();
    } catch (cameraError) {
      statusMessage(t('qr_fallback_camera'), 'error');
      return;
    }

    let detector = null;
    try {
      if ('BarcodeDetector' in window) detector = new window.BarcodeDetector({ formats: ['qr_code'] });
    } catch (_) { /* Use the local decoder when native QR detection is unavailable. */ }

    if (!detector && typeof window.jsQR !== 'function') {
      statusMessage(t('qr_fallback_detect'), 'error');
      return;
    }

    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d', { willReadFrequently: true });
    if (!context) {
      statusMessage(t('qr_fallback_detect'), 'error');
      return;
    }
    let scanning = false;
    timer = setInterval(async () => {
      if (settled || scanning || video.readyState < HTMLMediaElement.HAVE_CURRENT_DATA || !video.videoWidth) return;
      scanning = true;
      try {
        let value = '';
        if (detector) {
          try {
            const codes = await detector.detect(video);
            value = codes.find((code) => code.rawValue)?.rawValue || '';
          } catch (_) {
            detector = null;
          }
        }
        if (!value && window.jsQR) {
          const scale = Math.min(1, 640 / video.videoWidth);
          const width = Math.max(1, Math.round(video.videoWidth * scale));
          const height = Math.max(1, Math.round(video.videoHeight * scale));
          if (canvas.width !== width || canvas.height !== height) {
            canvas.width = width;
            canvas.height = height;
          }
          context.drawImage(video, 0, 0, width, height);
          const frame = context.getImageData(0, 0, width, height);
          value = window.jsQR(frame.data, width, height, { inversionAttempts: 'dontInvert' })?.data || '';
        }
        if (value) {
          settled = true;
          cleanup();
          modal.close(true);
          onResult(value);
        }
      } catch (_) { /* Skip this frame; keep the camera preview running. */ }
      finally { scanning = false; }
    }, 260);
  })();
}

/* ---------- 15. Receipt modal ---------- */
function openReceiptModal() {
  const modal = openModal(`
    <div class="modal-head"><div><div class="eyebrow">${t('m_receipt')}</div><h2>${t('m_receipt')}</h2></div>
      <button type="button" class="icon-ghost" data-close aria-label="Close">${icon('i-x', 'icon sm')}</button></div>
    <div class="camera-box" id="r-camera">
      <video id="r-cam" playsinline muted></video>
      <div class="camera-capture"><button type="button" class="btn primary sm" id="r-capture">${icon('i-scan', 'icon sm')} Capture photo</button></div>
    </div>
    <div class="field-hint" id="r-cam-status"></div>
    <label class="dropzone" id="r-drop">
      ${icon('i-scan')}
      <strong id="r-drop-title">${t('r_drop')}</strong>
      <small>JPEG, PNG or WebP · up to 5 MB</small>
      <input type="file" id="r-file" accept="image/jpeg,image/png,image/webp" hidden>
    </label>
    <label class="check-row"><input type="checkbox" id="r-consent">
      <span>I agree to send this receipt photo to the configured recognition provider for processing. Use a sample receipt for demos; don't upload sensitive personal details.</span></label>
    <button type="button" class="btn primary full" id="r-scan">${icon('i-scan', 'icon sm')} ${t('m_recognize')}</button>
    <div class="field-hint" id="r-status" role="status" aria-live="polite"></div>
    <form id="r-result" hidden>
      <div class="receipt-fields">
        <label class="field-label">Store / merchant<div class="input-wrap">${icon('i-cart', 'icon sm')}<input id="r-merchant" maxlength="200" placeholder="Store name"></div></label>
        <label class="field-label">Date<input id="r-date" type="date"></label>
        <label class="field-label">Total on receipt<input id="r-total" type="number" min="0.01" step="0.01" placeholder="0.00"></label>
        <label class="field-label">Currency on receipt<select id="r-currency">
          <option value="KZT">KZT — Kazakhstani tenge</option>
          <option value="RUB">RUB — Russian ruble</option>
          <option value="USD">USD — US dollar</option>
          <option value="EUR">EUR — euro</option>
        </select></label>
        <label class="field-label">Expense category<select id="r-category">${categoryOptions('expense')}</select></label>
        <label class="field-label">Amount to save (KZT)
          <div class="amount-input"><span>₸</span><input id="r-kzt" type="number" min="0.01" step="0.01" placeholder="0"></div></label>
      </div>
      <p class="receipt-note" id="r-note"></p>
      <div class="form-alert" id="r-alert" hidden></div>
      <div class="modal-actions">
        <button type="button" class="btn ghost" id="r-reset">Choose another</button>
        <button type="submit" class="btn primary" id="r-save">Confirm and save expense</button>
      </div>
    </form>`);

  const box = modal.box;
  const drop = box.querySelector('#r-drop');
  const fileInput = box.querySelector('#r-file');
  modal.setCloseHook(stopCamera);
  const status = box.querySelector('#r-status');
  const resultForm = box.querySelector('#r-result');
  let parsedReceipt = null;
  let file = null;
  let cameraStream = null;

  function statusMessage(text, type = '') {
    status.textContent = text;
    status.className = 'field-hint' + (type ? ' ' + type : '');
  }
  function camMessage(text, type = '') {
    const camStatus = box.querySelector('#r-cam-status');
    if (camStatus) {
      camStatus.textContent = text;
      camStatus.className = 'field-hint' + (type ? ' ' + type : '');
    }
  }
  function stopCamera() {
    if (cameraStream) {
      cameraStream.getTracks().forEach((t) => t.stop());
      cameraStream = null;
    }
  }
  function setFile(f) {
    file = f || null;
    drop.classList.toggle('has-file', !!file);
    box.querySelector('#r-drop-title').textContent = file ? file.name : 'Drop a receipt photo or browse';
  }
  function reset() {
    parsedReceipt = null;
    setFile(null);
    fileInput.value = '';
    resultForm.hidden = true;
    resultForm.reset();
    box.querySelector('#r-alert').hidden = true;
    statusMessage('');
  }

  // Camera opens immediately; capture feeds the same recognition flow as uploads.
  const camBox = box.querySelector('#r-camera');
  const camVideo = box.querySelector('#r-cam');
  const camStatus = box.querySelector('#r-cam-status');
  (async () => {
    if (!navigator.mediaDevices?.getUserMedia) {
      camStatus.textContent = 'Camera is not available here — choose a photo from your device below.';
      return;
    }
    try {
      cameraStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
      camVideo.srcObject = cameraStream;
      await camVideo.play();
    } catch (cameraError) {
      camBox.style.display = 'none';
      camStatus.textContent = 'Camera unavailable — choose a photo from your device below.';
    }
  })();

  box.querySelector('#r-capture').addEventListener('click', () => {
    if (!cameraStream || !camVideo.videoWidth) {
      camMessage('The camera is still starting — try again in a second.', 'error');
      return;
    }
    try {
      const canvas = document.createElement('canvas');
      canvas.width = camVideo.videoWidth;
      canvas.height = camVideo.videoHeight;
      canvas.getContext('2d').drawImage(camVideo, 0, 0);
      canvas.toBlob((blob) => {
        if (!blob) return camMessage('Could not capture the frame. Try again.', 'error');
        const captured = new File([blob], 'captured-receipt.jpg', { type: 'image/jpeg' });
        fileInput.value = '';
        setFile(captured);
        resultForm.hidden = true;
        statusMessage('Photo captured. Confirm the notice and recognize.');
        camMessage('');
      }, 'image/jpeg', 0.9);
    } catch (captureError) {
      camMessage('Could not capture the frame. Try again.', 'error');
    }
  });

  drop.addEventListener('click', () => fileInput.click());
  fileInput.addEventListener('change', () => setFile(fileInput.files[0]));
  ['dragover', 'dragenter'].forEach((evt) => drop.addEventListener(evt, (e) => { e.preventDefault(); drop.classList.add('dragover'); }));
  ['dragleave', 'drop'].forEach((evt) => drop.addEventListener(evt, (e) => { e.preventDefault(); drop.classList.remove('dragover'); }));
  drop.addEventListener('drop', (e) => {
    const dropped = e.dataTransfer?.files?.[0];
    if (dropped) { fileInput.files = e.dataTransfer.files; setFile(dropped); }
  });

  function mirrorKzt() {
    const currency = box.querySelector('#r-currency').value;
    const total = Number(box.querySelector('#r-total').value);
    const kzt = box.querySelector('#r-kzt');
    const note = box.querySelector('#r-note');
    if (currency === 'KZT') {
      kzt.value = total > 0 ? String(Math.round(total)) : '';
      note.textContent = 'Amounts are saved in KZT. Verify the recognized total before confirming.';
    } else {
      kzt.value = '';
      note.textContent = `Receipt currency is ${currency}. Convert it to KZT yourself and enter the KZT amount to save; the original amount and currency will be kept in the description.`;
    }
  }
  box.querySelector('#r-currency').addEventListener('change', mirrorKzt);
  box.querySelector('#r-total').addEventListener('input', () => {
    if (box.querySelector('#r-currency').value === 'KZT') mirrorKzt();
  });

  box.querySelector('#r-scan').addEventListener('click', async () => {
    if (!file) return statusMessage('Choose a receipt photo first.', 'error');
    if (!box.querySelector('#r-consent').checked) return statusMessage('Please confirm the processing notice first.', 'error');
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) return statusMessage('Unsupported image type — use JPEG, PNG or WebP.', 'error');
    if (file.size > 5 * 1024 * 1024) return statusMessage('The photo must be 5 MB or smaller.', 'error');
    const scanBtn = box.querySelector('#r-scan');
    scanBtn.disabled = true;
    scanBtn.classList.add('loading');
    statusMessage('Uploading securely for recognition. Please wait…');
    resultForm.hidden = true;
    try {
      parsedReceipt = await request('/receipts/parse', {
        method: 'POST',
        body: file,
        headers: { 'Content-Type': file.type },
      });
      box.querySelector('#r-merchant').value = parsedReceipt.merchant || '';
      box.querySelector('#r-date').value = parsedReceipt.date || todayISO();
      box.querySelector('#r-total').value = parsedReceipt.total ?? '';
      box.querySelector('#r-currency').value = RECEIPT_CURRENCIES.includes(parsedReceipt.currency) ? parsedReceipt.currency : 'KZT';
      const remembered = parsedReceipt.category;
      if (remembered && EXPENSE_CATEGORIES.includes(remembered)) box.querySelector('#r-category').value = remembered;
      mirrorKzt();
      resultForm.hidden = false;
      statusMessage('Recognition complete — check the details. Nothing is saved until you confirm.', 'success');
    } catch (err) {
      statusMessage((err.message || 'Recognition failed.') + ' You can retry or add the expense manually.', 'error');
    } finally {
      scanBtn.disabled = false;
      scanBtn.classList.remove('loading');
    }
  });

  resultForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!parsedReceipt) return statusMessage('Recognize a receipt before confirming.', 'error');
    const amount = Number(box.querySelector('#r-kzt').value);
    if (!Number.isFinite(amount) || amount <= 0) return statusMessage('Enter a valid expense amount in KZT.', 'error');
    const merchant = box.querySelector('#r-merchant').value.trim();
    const total = Number(box.querySelector('#r-total').value) || 0;
    const currency = box.querySelector('#r-currency').value;
    const original = `Receipt ${total.toFixed(2)} ${currency}`;
    const description = ((merchant ? merchant + ' — ' : '') + original).slice(0, 200);
    const saveBtn = box.querySelector('#r-save');
    saveBtn.disabled = true;
    try {
      await api('/transactions', {
        method: 'POST',
        body: JSON.stringify({
          kind: 'expense',
          amount_minor: Math.round(amount * 100),
          category: box.querySelector('#r-category').value,
          description,
          date: box.querySelector('#r-date').value || todayISO(),
          ...(merchant ? { merchant } : {}),
        }),
      });
      modal.close();
      toast('Receipt expense saved.');
      await loadAll();
    } catch (err) {
      if (!err.handled) {
        const alert = box.querySelector('#r-alert');
        alert.hidden = false;
        alert.textContent = err.message;
      }
      saveBtn.disabled = false;
    }
  });
  box.querySelector('#r-reset').addEventListener('click', reset);
}

/* ---------- 16. CSV import / export ---------- */
function downloadBlob(name, content, mime = 'text/csv') {
  const blob = new Blob([content], { type: mime + ';charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = name;
  document.body.append(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 4000);
}

const CSV_TEMPLATE = 'date,kind,amount,category,description\n2026-01-20,expense,1250.50,Groceries,Weekly shop\n2026-01-21,income,520000,Salary,January salary';

function openImportModal() {
  const modal = openModal(`
    <div class="modal-head"><div><div class="eyebrow">${t('m_import')}</div><h2>${t('m_import')}</h2></div>
      <button type="button" class="icon-ghost" data-close aria-label="Close">${icon('i-x', 'icon sm')}</button></div>
    <p class="muted" style="font-size:12px;line-height:1.6;margin-bottom:14px">Upload or paste a CSV. Headers must include <strong>date, kind, amount, category</strong>; <strong>description</strong> is optional. Amounts are decimal tenge (e.g. 1250.50) and the ledger stays in KZT. Up to 1000 rows per import; identical files are skipped automatically.</p>
    <label class="dropzone" id="im-drop">
      ${icon('i-file')}
      <strong>Choose a .csv file</strong>
      <small>or paste the text below</small>
      <input type="file" id="im-file" accept=".csv,text/csv,text/plain" hidden>
    </label>
    <textarea class="paste-area" id="im-text" rows="5" placeholder="date,kind,amount,category,description&#10;2026-01-20,expense,1250.50,Groceries,Weekly shop" spellcheck="false"></textarea>
    <div class="form-alert" id="im-alert" hidden></div>
    <div class="modal-actions">
      <button type="button" class="btn ghost sm" id="im-tpl">${icon('i-download', 'icon xs')} Template</button>
      <button type="button" class="btn primary" id="im-save">${icon('i-upload', 'icon sm')} ${t('import_csv')}</button>
    </div>`);

  const box = modal.box;
  const text = box.querySelector('#im-text');
  const fileInput = box.querySelector('#im-file');
  const drop = box.querySelector('#im-drop');
  drop.addEventListener('click', () => fileInput.click());
  fileInput.addEventListener('change', async () => {
    const f = fileInput.files[0];
    if (!f) return;
    if (f.size > 120000) {
      const alert = box.querySelector('#im-alert');
      alert.hidden = false;
      alert.textContent = 'The file must be 120 KB or smaller.';
      return;
    }
    text.value = await f.text();
  });
  box.querySelector('#im-tpl').addEventListener('click', () => downloadBlob('smart-finance-template.csv', CSV_TEMPLATE));
  box.querySelector('#im-save').addEventListener('click', async () => {
    const content = text.value;
    if (!content.trim()) {
      const alert = box.querySelector('#im-alert');
      alert.hidden = false;
      alert.textContent = 'Paste CSV text or choose a file first.';
      return;
    }
    const saveBtn = box.querySelector('#im-save');
    saveBtn.disabled = true;
    saveBtn.classList.add('loading');
    try {
      const result = await api('/transactions/import', { method: 'POST', body: JSON.stringify({ csv: content }) });
      modal.close();
      if (result.duplicate) toast(t('toast_import_dup'), 'info');
      else toast(t('toast_imported', { n: result.imported }));
      await loadAll();
    } catch (err) {
      if (!err.handled) {
        const alert = box.querySelector('#im-alert');
        alert.hidden = false;
        alert.textContent = err.message;
      }
      saveBtn.disabled = false;
      saveBtn.classList.remove('loading');
    }
  });
}

function exportCsv() {
  if (!state.transactions.length) return toast('Nothing to export yet.', 'info');
  const quote = (v) => '"' + String(v ?? '').replace(/"/g, '""') + '"';
  const rows = ['date,kind,amount,category,description'];
  for (const t of [...state.transactions].sort((a, b) => String(a.created_at).localeCompare(b.created_at))) {
    rows.push([
      String(t.created_at).slice(0, 10),
      t.kind,
      (Number(t.amount_minor) / 100).toFixed(2),
      quote(t.category),
      quote(t.description),
    ].join(','));
  }
  const d = new Date();
  const stamp = d.getFullYear() + String(d.getMonth() + 1).padStart(2, '0') + String(d.getDate()).padStart(2, '0');
  downloadBlob(`smart-finance-transactions-${stamp}.csv`, rows.join('\n'));
  toast(t('toast_exported', { n: state.transactions.length }), 'info');
}

/* ---------- 17. Budget & goal modals ---------- */
function monthOptions(selected) {
  const keys = [];
  const now = new Date();
  for (let i = 0; i < 12; i++) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    keys.push(monthKeyOf(d));
  }
  if (!keys.includes(selected)) keys.unshift(selected);
  return keys.map((k) => `<option value="${k}"${k === selected ? ' selected' : ''}>${monthLabel(k)}</option>`).join('');
}

function openBudgetModal(row) {
  const editing = !!row;
  const modal = openModal(`
    <div class="modal-head"><div><div class="eyebrow">${t('m_budget_month')}</div><h2>${editing ? t('m_budget_edit') : t('m_budget_t')}</h2></div>
      <button type="button" class="icon-ghost" data-close aria-label="Close">${icon('i-x', 'icon sm')}</button></div>
    <form id="b-form" novalidate>
      <label class="field-label">${t('m_budget_cat')}<select id="b-cat">
        <option value="*">${t('m_budget_all')}</option>
        ${EXPENSE_CATEGORIES.map((c) => `<option value="${esc(c)}"${row?.category === c ? ' selected' : ''}>${esc(catLabelT(c))}</option>`).join('')}
      </select></label>
      <label class="field-label">${t('m_budget_month')}<select id="b-month">${monthOptions(row?.month || state.planMonth)}</select></label>
      <label class="field-label">${t('m_budget_limit')}
        <div class="amount-input"><span>₸</span><input id="b-amount" type="number" min="1" step="1" placeholder="0" value="${editing ? row.amount_minor / 100 : ''}" required></div></label>
      <div class="form-alert" id="b-alert" hidden></div>
      <div class="modal-actions">
        <button type="button" class="btn ghost" data-close>Cancel</button>
        <button type="submit" class="btn primary">${editing ? t('m_save_budget') : t('m_budget_save')}</button>
      </div>
    </form>`, { narrow: true });
  const box = modal.box;
  if (editing && row.category === '*') box.querySelector('#b-cat').value = '*';
  else if (editing) box.querySelector('#b-cat').value = row.category;

  box.querySelector('#b-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const category = box.querySelector('#b-cat').value;
    const month = box.querySelector('#b-month').value;
    const amount = Number(box.querySelector('#b-amount').value);
    const alert = box.querySelector('#b-alert');
    if (!Number.isFinite(amount) || amount <= 0) {
      alert.hidden = false; alert.textContent = 'Enter a limit greater than zero.';
      return;
    }
    try {
      await api('/budgets', {
        method: 'POST',
        body: JSON.stringify({ month, category, amount_minor: Math.round(amount * 100) }),
      });
      modal.close();
      toast(t('toast_budget'));
      await loadAll();
    } catch (err) {
      if (!err.handled) { alert.hidden = false; alert.textContent = err.message; }
    }
  });
}

function openGoalModal() {
  const modal = openModal(`
    <div class="modal-head"><div><div class="eyebrow">${t('sec_goals')}</div><h2>${t('m_goal_t')}</h2></div>
      <button type="button" class="icon-ghost" data-close aria-label="Close">${icon('i-x', 'icon sm')}</button></div>
    <form id="g-form" novalidate>
      <label class="field-label">${t('m_goal_name')}<div class="input-wrap">${icon('i-target', 'icon sm')}<input id="g-name" maxlength="100" placeholder="e.g. New laptop" required></div></label>
      <label class="field-label">${t('m_goal_target')}
        <div class="amount-input"><span>₸</span><input id="g-target" type="number" min="1" step="1" placeholder="0" required></div></label>
      <label class="field-label">${t('m_goal_saved')}
        <div class="amount-input"><span>₸</span><input id="g-saved" type="number" min="0" step="1" placeholder="0" value="0"></div></label>
      <div class="form-alert" id="g-alert" hidden></div>
      <div class="modal-actions">
        <button type="button" class="btn ghost" data-close>Cancel</button>
        <button type="submit" class="btn primary">${t('m_goal_create')}</button>
      </div>
    </form>`, { narrow: true });
  const box = modal.box;
  box.querySelector('#g-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = box.querySelector('#g-name').value.trim();
    const target = Number(box.querySelector('#g-target').value);
    const saved = Number(box.querySelector('#g-saved').value) || 0;
    const alert = box.querySelector('#g-alert');
    if (!name) { alert.hidden = false; alert.textContent = 'Give the goal a name.'; return; }
    if (!Number.isFinite(target) || target <= 0) { alert.hidden = false; alert.textContent = 'Enter a target greater than zero.'; return; }
    if (saved > target) { alert.hidden = false; alert.textContent = 'Saved cannot exceed the target.'; return; }
    try {
      await api('/goals', {
        method: 'POST',
        body: JSON.stringify({ name, target_minor: Math.round(target * 100), saved_minor: Math.round(saved * 100) }),
      });
      modal.close();
      toast(t('toast_goal'));
      await loadAll();
    } catch (err) {
      if (!err.handled) { alert.hidden = false; alert.textContent = err.message; }
    }
  });
}

function openTopupModal(goal, editMode) {
  const modal = openModal(`
    <div class="modal-head"><div><div class="eyebrow">${editMode ? t('update_progress') : t('add_funds')}</div><h2>${esc(goal.name)}</h2></div>
      <button type="button" class="icon-ghost" data-close aria-label="Close">${icon('i-x', 'icon sm')}</button></div>
    <form id="t-form" novalidate>
      <p class="muted" style="font-size:12px;margin-bottom:14px">${t('saved_of_pct', { a: fmtMoney(goal.saved_minor), b: fmtMoney(goal.target_minor), p: percentOf(goal.saved_minor, goal.target_minor) })}</p>
      ${editMode ? '' : `<div class="quick-chips">
        <button type="button" class="chip" data-add="10000">+₸ 10,000</button>
        <button type="button" class="chip" data-add="50000">+₸ 50,000</button>
        <button type="button" class="chip" data-add="100000">+₸ 100,000</button>
      </div>`}
      <label class="field-label">${editMode ? t('total_saved_kzt') : t('add_amount_kzt')}
        <div class="amount-input"><span>₸</span><input id="t-amount" type="number" min="0" step="1" placeholder="0" value="${editMode ? goal.saved_minor / 100 : ''}" required></div></label>
      <div class="form-alert" id="t-alert" hidden></div>
      <div class="modal-actions">
        <button type="button" class="btn ghost" data-close>${t('m_cancel')}</button>
        <button type="submit" class="btn primary">${editMode ? t('update_progress') : t('add_funds')}</button>
      </div>
    </form>`, { narrow: true });
  const box = modal.box;
  const input = box.querySelector('#t-amount');
  box.querySelectorAll('[data-add]').forEach((chipBtn) => {
    chipBtn.addEventListener('click', () => {
      input.value = String(Math.round((Number(input.value) || 0) + Number(chipBtn.dataset.add)));
    });
  });
  box.querySelector('#t-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const amount = Number(input.value);
    const alert = box.querySelector('#t-alert');
    if (!Number.isFinite(amount) || amount < 0) { alert.hidden = false; alert.textContent = 'Enter a valid amount.'; return; }
    const saved = editMode ? Math.round(amount * 100) : Math.min(goal.target_minor, goal.saved_minor + Math.round(amount * 100));
    try {
      const updated = await api('/goals/update', {
        method: 'POST',
        body: JSON.stringify({ id: goal.id, saved_minor: saved }),
      });
      modal.close();
      toast(updated.saved_minor >= updated.target_minor ? t('toast_goal_hit') : t('toast_goal_upd'));
      await loadAll();
    } catch (err) {
      if (!err.handled) { alert.hidden = false; alert.textContent = err.message; }
    }
  });
}

/* ---------- 18. Auth screen ---------- */
function showAuth() {
  state.ready = false;
  $('app').hidden = true;
  $('authScreen').hidden = false;
  const user = $('authUser');
  if (user && document.activeElement !== user) user.focus();
}

function wireAuth() {
  const form = $('authForm');
  const user = $('authUser');
  const pass = $('authPass');
  const toggle = $('registerMode');
  const passToggle = $('passToggle');
  const submit = $('authSubmit');
  const error = $('authError');

  passToggle.addEventListener('click', () => {
    const showing = pass.type === 'text';
    pass.type = showing ? 'password' : 'text';
    passToggle.innerHTML = icon(showing ? 'i-eye' : 'i-eye-off', 'icon sm');
    passToggle.setAttribute('aria-label', showing ? 'Show password' : 'Hide password');
  });

  function syncMode() {
    const registering = toggle.checked;
    $('authTitle').textContent = registering ? t('auth_create') : t('auth_welcome');
    $('authSubtitle').textContent = registering ? t('auth_sub_reg') : t('auth_sub');
    submit.textContent = registering ? t('create_acc') : t('signin');
    pass.setAttribute('autocomplete', registering ? 'new-password' : 'current-password');
  }
  toggle.addEventListener('change', syncMode);

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    error.hidden = true;
    const username = user.value.trim();
    const password = pass.value;
    const registering = toggle.checked;
    submit.disabled = true;
    submit.textContent = registering ? 'Creating account…' : 'Signing in…';
    try {
      const result = await request(registering ? '/auth/register' : '/auth/login', {
        method: 'POST',
        body: JSON.stringify({ username, password }),
      });
      state.token = result.token;
      localStorage.setItem('sf_token', result.token);
      $('authScreen').hidden = true;
      showAppSkeletons();
      await loadAll();
      if (state.ready) toast(t('toast_welcome', { u: result.user.username }), 'info');
    } catch (err) {
      error.hidden = false;
      error.textContent = err.status === 0
        ? 'The server is not reachable. Start it with START_LOCAL.cmd, then try again.'
        : (err.message || 'Something went wrong. Try again.');
    } finally {
      submit.disabled = false;
      syncMode();
    }
  });
}

function signOut(message) {
  const token = state.token;
  state.token = '';
  localStorage.removeItem('sf_token');
  if (token) {
    request('/auth/logout', { method: 'POST' }).catch(() => { /* session cleanup is best-effort */ });
  }
  showAuth();
  if (message) toast(message, 'info');
}

/* ---------- 19. Data loading & rendering ---------- */
function showAppSkeletons() {
  $('app').hidden = false;
  ['statGrid', 'cashChart', 'budgetSnapshot', 'recentRows', 'overviewGoals', 'txStats',
    'allRows', 'insightStats', 'catChart', 'observations', 'trendChart',
    'planningSummary', 'budgetsList', 'goalsGrid'].forEach((id) => fillSkeleton($(id), 3));
}

async function loadAll() {
  let results;
  try {
    results = await Promise.all([
      request('/auth/me'),
      request('/transactions'),
      request('/summary'),
      request('/analytics').catch(() => FALLBACK_ANALYTICS),
      request('/goals'),
      request('/budgets?month=' + state.planMonth).catch(() => []),
    ]);
  } catch (err) {
    if (err instanceof ApiError && err.status === 401) {
      signOut('Session expired — please sign in again.');
      return;
    }
    showAuth();
    toast('Backend is not reachable. Start it with START_LOCAL.cmd.', 'error');
    return;
  }
  const [me, transactions, summary, analytics, goals, budgets] = results;
  state.user = me;
  state.transactions = Array.isArray(transactions) ? transactions : [];
  state.summary = summary;
  state.analytics = { ...FALLBACK_ANALYTICS, ...analytics };
  state.goals = Array.isArray(goals) ? goals : [];
  state.budgets = Array.isArray(budgets) ? budgets : [];
  state.ready = true;
  renderAll();
}

function renderAll() {
  applyI18n();
  renderProfile();
  renderChips();
  renderGreeting();
  renderStatGrid();
  renderCashflow();
  renderBudgetSnapshot();
  renderRecent();
  renderOverviewGoals();
  renderTxStats();
  renderTxFilters();
  renderTxTable();
  renderInsightStats();
  renderDonut();
  renderObservations();
  renderTrendChart();
  renderPlanningMonth();
  renderPlanningSummary();
  renderBudgetsList();
  renderGoalsGrid();
}

/* ---------- 20. Navigation & chrome events ---------- */
function showPage(name) {
  if (!PAGES[name]) name = 'overview';
  document.querySelectorAll('.page').forEach((p) => p.classList.toggle('active-page', p.id === `page-${name}`));
  document.querySelectorAll('.sidebar .nav-item').forEach((b) => b.classList.toggle('active', b.dataset.page === name));
  document.querySelectorAll('.tabbar .tab-item').forEach((b) => b.classList.toggle('active', b.dataset.page === name));
  window.scrollTo({ top: 0, left: 0, behavior: REDUCED_MOTION ? 'auto' : 'smooth' });
}

function applyTheme(theme) {
  const resolved = theme === 'system'
    ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
    : (theme || 'dark');
  document.documentElement.dataset.theme = resolved;
  try { localStorage.setItem('sf_theme', theme); } catch (_) { /* private mode */ }
  state.settings.theme = theme;
  const btn = $('themeBtn');
  if (btn) btn.innerHTML = icon(resolved === 'dark' ? 'i-sun' : 'i-moon', 'icon sm');
}

function wireTheme() {
  const btn = $('themeBtn');
  const sync = () => {
    const dark = document.documentElement.dataset.theme === 'dark';
    btn.innerHTML = icon(dark ? 'i-sun' : 'i-moon', 'icon sm');
  };
  sync();
  btn.addEventListener('click', () => {
    applyTheme(document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark');
    sync();
  });
}

function wireStaticEvents() {
  document.addEventListener('click', (e) => {
    const pageButton = e.target.closest('[data-page]');
    if (pageButton) {
      e.preventDefault();
      showPage(pageButton.dataset.page);
      return;
    }
    if (e.target.closest('[data-privacy]')) {
      const hidden = document.body.classList.toggle('privacy');
      toast(hidden ? t('toast_hidden') : t('toast_visible'), 'info');
      return;
    }
    if (e.target.closest('[data-open-scan]')) { openReceiptModal(); return; }
    if (e.target.closest('[data-open-tx]')) { openTxModal(); return; }
    if (e.target.closest('[data-open-goal]')) { openGoalModal(); return; }
    if (e.target.closest('[data-open-budget]')) { openBudgetModal(null); return; }
  });

  document.querySelectorAll('#cashflowSeg .seg-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      state.cashflowMonths = Number(btn.dataset.months) || 6;
      document.querySelectorAll('#cashflowSeg .seg-btn').forEach((b) => b.classList.toggle('active', b === btn));
      renderCashflow();
    });
  });

  wireTheme();

  $('accountBtn')?.addEventListener('click', openAccountSheet);
  wirePullToRefresh();

  $('logoutBtn').addEventListener('click', async () => {
    const ok = await confirmDialog({
      title: t('conf_sign_out'),
      message: t('conf_sign_out_d'),
      confirmLabel: t('sign_out'),
    });
    if (!ok) return;
    signOut(t('toast_signed_out'));
  });

  /* Transactions filters */
  let searchTimer = null;
  $('searchInput').addEventListener('input', (e) => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      state.filters.q = e.target.value;
      state.filters.page = 1;
      renderTxTable();
    }, 150);
  });
  $('typeFilter').addEventListener('change', (e) => { state.filters.type = e.target.value; state.filters.page = 1; renderTxTable(); });
  $('categoryFilter').addEventListener('change', (e) => { state.filters.category = e.target.value; state.filters.page = 1; renderTxTable(); });
  $('monthFilter').addEventListener('change', (e) => { state.filters.month = e.target.value; state.filters.page = 1; renderTxTable(); });

  $('allRows').addEventListener('click', async (e) => {
    const del = e.target.closest('[data-del-tx]');
    if (!del) return;
    const id = Number(del.dataset.delTx);
    const tx = state.transactions.find((t) => t.id === id);
    if (!tx) return;
    const ok = await confirmDialog({
      title: t('conf_del_tx'),
      message: t('conf_del_tx_d', { n: txName(tx) }),
    });
    if (!ok) return;
    try {
      await api('/transactions/delete', { method: 'POST', body: JSON.stringify({ id }) });
      toast(t('toast_deleted'));
      await loadAll();
    } catch (err) {
      if (!err.handled) toast(err.message, 'error');
    }
  });
  $('pager').addEventListener('click', (e) => {
    const btn = e.target.closest('[data-page-go]');
    if (!btn || btn.disabled) return;
    state.filters.page = Number(btn.dataset.pageGo);
    renderTxTable();
  });

  $('importBtn').addEventListener('click', openImportModal);
  $('exportBtn').addEventListener('click', exportCsv);
  $('scanBtn').addEventListener('click', openReceiptModal);
  $('scanBtn2').addEventListener('click', openReceiptModal);

  /* Planning */
  $('monthPrev').addEventListener('click', () => {
    state.planMonth = shiftMonth(state.planMonth, -1);
    refreshPlanning();
  });
  $('monthNext').addEventListener('click', () => {
    state.planMonth = shiftMonth(state.planMonth, 1);
    refreshPlanning();
  });
  $('addBudgetBtn').addEventListener('click', () => openBudgetModal(null));
  $('addGoalBtn').addEventListener('click', openGoalModal);

  $('budgetsList').addEventListener('click', async (e) => {
    const editBtn = e.target.closest('[data-edit-budget]');
    const delBtn = e.target.closest('[data-del-budget]');
    if (editBtn) {
      const row = state.budgets.find((b) => b.id === Number(editBtn.dataset.editBudget));
      if (row) openBudgetModal(row);
      return;
    }
    if (delBtn) {
      const row = state.budgets.find((b) => b.id === Number(delBtn.dataset.delBudget));
      if (!row) return;
      const ok = await confirmDialog({
        title: t('conf_del_budget'),
        message: t('conf_del_budget_d', { c: catLabel(row.category), m: monthLabel(row.month) }),
      });
      if (!ok) return;
      try {
        await api('/budgets/delete', { method: 'POST', body: JSON.stringify({ id: row.id }) });
        toast(t('toast_budget_del'));
        await loadAll();
      } catch (err) {
        if (!err.handled) toast(err.message, 'error');
      }
    }
  });

  $('goalsGrid').addEventListener('click', async (e) => {
    const topup = e.target.closest('[data-topup]');
    const edit = e.target.closest('[data-edit-goal]');
    const del = e.target.closest('[data-del-goal]');
    if (topup) {
      const goal = state.goals.find((g) => g.id === Number(topup.dataset.topup));
      if (goal) openTopupModal(goal, false);
      return;
    }
    if (edit) {
      const goal = state.goals.find((g) => g.id === Number(edit.dataset.editGoal));
      if (goal) openTopupModal(goal, true);
      return;
    }
    if (del) {
      const goal = state.goals.find((g) => g.id === Number(del.dataset.delGoal));
      if (!goal) return;
      const ok = await confirmDialog({
        title: t('conf_del_goal'),
        message: t('conf_del_goal_d', { n: goal.name }),
      });
      if (!ok) return;
      try {
        await api('/goals/delete', { method: 'POST', body: JSON.stringify({ id: goal.id }) });
        toast(t('toast_goal_del'));
        await loadAll();
      } catch (err) {
        if (!err.handled) toast(err.message, 'error');
      }
    }
  });
}

async function refreshPlanning() {
  renderPlanningMonth();
  try {
    state.budgets = await request('/budgets?month=' + state.planMonth);
  } catch (err) {
    if (err instanceof ApiError && err.status === 401 && state.ready) { signOut('Session expired — please sign in again.'); return; }
    state.budgets = [];
  }
  renderPlanningSummary();
  renderBudgetsList();
}

/* ---------- 20b. Account & settings sheet ---------- */
function openAccountSheet() {
  const theme = settings.theme || 'dark';
  const modal = openModal(`
    <div class="modal-head"><div><div class="eyebrow">${t('acc_settings')}</div><h2>${esc(displayName())}</h2></div>
      <button type="button" class="icon-ghost" data-close aria-label="Close">${icon('i-x', 'icon sm')}</button></div>

    <div class="set-section">
      <div class="set-title">${t('profile')}</div>
      <div class="set-profile">
        <span class="avatar-btn">${initials(displayName())}</span>
        <div class="set-profile-copy"><strong>${esc(displayName())}</strong><small>@${esc(state.user?.username || '')} &middot; ${t('stored_server')}</small></div>
      </div>
      <label class="field-label">${t('display_name')}
        <div class="input-wrap">${icon('i-user', 'icon sm')}<input id="set-name" maxlength="40" placeholder="${esc(state.user?.username || '')}" value="${esc(settings.displayName)}"></div>
      </label>
      <button type="button" class="btn primary sm" id="set-name-save">${t('save_name')}</button>
    </div>

    <div class="set-section">
      <div class="set-title">${t('appearance')}</div>
      <div class="set-theme-block">
        <div class="set-title-sm">${t('theme_label')}</div>
        <div class="seg" id="set-theme" role="group" aria-label="Theme">
          <button class="seg-btn${theme === 'light' ? ' active' : ''}" data-theme-opt="light">${t('theme_light')}</button>
          <button class="seg-btn${theme === 'dark' ? ' active' : ''}" data-theme-opt="dark">${t('theme_dark')}</button>
          <button class="seg-btn${theme === 'system' ? ' active' : ''}" data-theme-opt="system">${t('theme_system')}</button>
        </div>
      </div>
      <div class="set-row" style="margin-top:10px"><span class="set-label">${t('hide_amounts')}</span>
        <label class="set-toggle"><input type="checkbox" id="set-privacy"${settings.privacyStart ? ' checked' : ''}><i></i></label></div>
    </div>

    <div class="set-section">
      <div class="set-title">${t('sec_data')}</div>
      <div class="set-row"><span class="set-label">${t('rows_per_page')}</span>
        <select id="set-rows" class="select"><option value="10"${settings.rows === 10 ? ' selected' : ''}>10</option><option value="25"${settings.rows === 25 ? ' selected' : ''}>25</option><option value="50"${settings.rows === 50 ? ' selected' : ''}>50</option></select></div>
      <div class="set-row"><span class="set-label">${t('start_screen')}</span>
        <select id="set-start" class="select"><option value="overview"${settings.startPage === 'overview' ? ' selected' : ''}>${t('nav_overview')}</option><option value="transactions"${settings.startPage === 'transactions' ? ' selected' : ''}>${t('nav_transactions')}</option><option value="insights"${settings.startPage === 'insights' ? ' selected' : ''}>${t('nav_insights')}</option><option value="planning"${settings.startPage === 'planning' ? ' selected' : ''}>${t('nav_planning')}</option></select></div>
      <div class="set-row"><span class="set-label">${t('currency_display')}<small>${t('currency_note')}</small></span>
        <select id="set-currency" class="select"><option value="KZT"${settings.currency === 'KZT' ? ' selected' : ''}>KZT \u20b8</option><option value="USD"${settings.currency === 'USD' ? ' selected' : ''}>USD $</option><option value="EUR"${settings.currency === 'EUR' ? ' selected' : ''}>EUR \u20ac</option><option value="GBP"${settings.currency === 'GBP' ? ' selected' : ''}>GBP \u00a3</option><option value="RUB"${settings.currency === 'RUB' ? ' selected' : ''}>RUB \u20bd</option><option value="CNY"${settings.currency === 'CNY' ? ' selected' : ''}>CNY \u00a5</option><option value="JPY"${settings.currency === 'JPY' ? ' selected' : ''}>JPY \u00a5</option></select></div>
    </div>

    <div class="set-section">
      <div class="set-title">${t('lang_title')}</div>
      <div class="flag-row">
        <button type="button" class="flag-btn${LANG === 'kz' ? ' active' : ''}" data-lang="kz">${flagSvg('kz')}<span>Қазақша</span></button>
        <button type="button" class="flag-btn${LANG === 'ru' ? ' active' : ''}" data-lang="ru">${flagSvg('ru')}<span>Русский</span></button>
        <button type="button" class="flag-btn${LANG === 'en' ? ' active' : ''}" data-lang="en">${flagSvg('en')}<span>English</span></button>
      </div>
    </div>

    <div class="set-section">
      <div class="set-title">${t('about')}</div>
      <p class="set-about">${t('about_text')}</p>
    </div>

    <button type="button" class="btn danger full" id="set-logout">${icon('i-logout', 'icon sm')} ${t('sign_out')}</button>
  `, { onClose: null });

  const box = modal.box;

  box.querySelector('#set-name-save').addEventListener('click', () => {
    const value = box.querySelector('#set-name').value.trim();
    settings.displayName = value;
    try { localStorage.setItem('sf_display_name', value); } catch (_) {}
    renderProfile();
    renderGreeting();
    const head = box.querySelector('.modal-head h2');
    if (head) head.textContent = displayName();
    const copy = box.querySelector('.set-profile-copy strong');
    if (copy) copy.textContent = displayName();
    const av = box.querySelector('.set-profile .avatar-btn');
    if (av) av.textContent = initials(displayName());
    toast(t('toast_name_saved'), 'success');
  });

  box.querySelectorAll('#set-theme .seg-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      box.querySelectorAll('#set-theme .seg-btn').forEach((b) => b.classList.toggle('active', b === btn));
      applyTheme(btn.dataset.themeOpt);
    });
  });

  box.querySelector('#set-privacy').addEventListener('change', (e) => {
    settings.privacyStart = e.target.checked;
    try { localStorage.setItem('sf_privacy_start', e.target.checked ? '1' : '0'); } catch (_) {}
    toast(settings.privacyStart ? t('toast_priv_on') : t('toast_priv_off'), 'info');
  });

  box.querySelector('#set-rows').addEventListener('change', (e) => {
    settings.rows = Number(e.target.value) || 10;
    PAGE_SIZE = settings.rows;
    try { localStorage.setItem('sf_rows', String(settings.rows)); } catch (_) {}
    state.filters.page = 1;
    renderTxTable();
    toast(t('toast_rows'), 'success');
  });

  box.querySelector('#set-start').addEventListener('change', (e) => {
    settings.startPage = e.target.value;
    try { localStorage.setItem('sf_start_page', settings.startPage); } catch (_) {}
    toast(t('toast_start'), 'success');
  });

  box.querySelector('#set-currency').addEventListener('change', (e) => {
    settings.currency = e.target.value;
    try { localStorage.setItem('sf_currency', settings.currency); } catch (_) {}
    renderAll();
    toast(t('toast_cur', { c: settings.currency }), 'info');
  });

  box.querySelectorAll('.flag-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      applyLang(btn.dataset.lang);
    });
  });

  box.querySelector('#set-logout').addEventListener('click', async () => {
    const ok = await confirmDialog({
      title: 'Sign out?',
      message: 'Your session token will be revoked on the server. Your data stays safely stored.',
      confirmLabel: 'Sign out',
    });
    if (!ok) return;
    signOut('Signed out.');
  });
}

/* ---------- 20c. Pull-to-refresh ---------- */
function applyLang(lang) {
  LANG = lang;
  try { localStorage.setItem('sf_lang', lang); } catch (_) {}
  applyI18n();
  renderAll();
}

function wirePullToRefresh() {
  const indicator = $('ptr');
  if (!indicator) return;
  let startY = null;
  let pull = 0;
  let refreshing = false;
  const THRESHOLD = 60;
  const progressArc = indicator.querySelector('.ptr-progress');
  const circumference = 2 * Math.PI * 9;

  function reset() {
    startY = null;
    pull = 0;
    indicator.classList.remove('visible', 'refreshing');
    indicator.style.removeProperty('--ptr-y');
    if (progressArc) progressArc.style.strokeDashoffset = '';
  }

  window.addEventListener('touchstart', (e) => {
    if (!state.ready || document.body.style.overflow === 'hidden') return;
    startY = window.scrollY <= 0 ? e.touches[0].clientY : null;
  }, { passive: true });

  window.addEventListener('touchmove', (e) => {
    if (startY === null || refreshing) return;
    const delta = e.touches[0].clientY - startY;
    if (delta <= 0) {
      indicator.classList.remove('visible');
      indicator.style.removeProperty('--ptr-y');
      if (progressArc) progressArc.style.strokeDashoffset = '';
      return;
    }
    pull = Math.min(delta * 0.55, 90);
    indicator.classList.add('visible');
    indicator.style.setProperty('--ptr-y', `${Math.min(pull, 74) - 56}px`);
    if (progressArc) progressArc.style.strokeDashoffset = String(circumference * (1 - Math.min(pull / THRESHOLD, 1)));
    if (e.cancelable && pull > 8) e.preventDefault();
  }, { passive: false });

  window.addEventListener('touchend', async () => {
    if (startY === null) return;
    const shouldRefresh = pull >= THRESHOLD && !refreshing;
    startY = null;
    pull = 0;
    if (shouldRefresh) {
      refreshing = true;
      indicator.classList.add('refreshing');
      indicator.style.setProperty('--ptr-y', '8px');
      try {
        await loadAll();
        toast(t('toast_refreshed'), 'info');
      } catch (_) { /* handled in loadAll */ }
      refreshing = false;
      reset();
    } else {
      reset();
    }
  });
}

/* ---------- 21. Boot ---------- */
(async function boot() {
  try {
    wireStaticEvents();
    wireAuth();
    if (!state.token) { showAuth(); return; }
    if (settings.privacyStart) document.body.classList.add('privacy');
    showAppSkeletons();
    await loadAll();
    applyI18n();
    renderAll();
    if (state.ready && PAGES[settings.startPage] && settings.startPage !== 'overview') {
      showPage(settings.startPage);
    }
  } catch (unexpected) {
    toast('Something went wrong while starting the app. Please refresh.', 'error');
  }
})();
