import { useState } from 'react'

type Route = 'home' | 'catalog' | 'ar' | 'cart' | 'profile'
type AuthScreen = 'login' | 'register' | 'recovery'

const navItems: { route: Route; label: string; icon: string }[] = [
  { route: 'home', label: 'Главная', icon: '/assets/0471c.svg' },
  { route: 'catalog', label: 'Каталог', icon: '/assets/04e7c.svg' },
  { route: 'ar', label: 'AR', icon: '/assets/08fc5.svg' },
  { route: 'cart', label: 'Корзина', icon: '/assets/052e4.svg' },
  { route: 'profile', label: 'Профиль', icon: '/assets/06fdf.svg' },
]

const routeTitles: Record<Route, string> = {
  home: 'Дом для своих вещей',
  catalog: 'Каталог',
  ar: 'Примерка в AR',
  cart: 'Корзина',
  profile: 'Профиль',
}

function LocalIcon({ src, label }: { src: string; label: string }) {
  return <img className="local-icon" src={src} alt="" aria-hidden="true" title={label} />
}

function BottomNavigation({ route, onNavigate }: { route: Route; onNavigate: (route: Route) => void }) {
  return <nav className="bottom-navigation" aria-label="Основная навигация">{navItems.map((item) => <button key={item.route} className={`nav-item ${item.route === 'ar' ? 'nav-item-ar' : ''} ${route === item.route ? 'is-active' : ''}`} onClick={() => onNavigate(item.route)} aria-label={item.label} aria-current={route === item.route ? 'page' : undefined}><span className="nav-icon-wrap"><LocalIcon src={item.icon} label={item.label} /></span><span>{item.label}</span></button>)}</nav>
}

function AuthForm({ screen, onScreenChange, onSuccess }: { screen: AuthScreen; onScreenChange: (screen: AuthScreen) => void; onSuccess: () => void }) {
  const isRegister = screen === 'register'
  const isRecovery = screen === 'recovery'
  const title = isRecovery ? 'Вернуть доступ' : isRegister ? 'Создать аккаунт' : 'Войти в приложение'
  const subtitle = isRecovery ? 'Укажи email или телефон, и мы пришлём ссылку для восстановления.' : isRegister ? 'Сохраняй любимые вещи и свои AR-сцены.' : 'Продолжи выбирать вещи для своего дома.'
  return <section className="auth-sheet" aria-labelledby="auth-title"><div className="auth-ornament" aria-hidden="true"><span>✦</span><i /><span>✦</span></div><p className="auth-kicker">Приялье · маркетплейс дома</p><h1 id="auth-title">{title}</h1><p className="auth-subtitle">{subtitle}</p><form className="auth-form" onSubmit={(event) => { event.preventDefault(); onSuccess() }}>{isRegister && <label><span>Имя</span><input required type="text" placeholder="Как к тебе обращаться" /></label>}<label><span>Email или телефон</span><input required type={isRecovery ? 'text' : 'email'} placeholder="you@example.com" /></label>{!isRecovery && <label><span>Пароль</span><input required minLength={6} type="password" placeholder="Не менее 6 символов" /></label>}<button className="wood-button wood-button-primary" type="submit">{isRecovery ? 'Отправить ссылку' : isRegister ? 'Зарегистрироваться' : 'Войти'}</button></form><div className="auth-links">{!isRegister && !isRecovery && <button onClick={() => onScreenChange('recovery')}>Забыли пароль?</button>}{isRecovery && <button onClick={() => onScreenChange('login')}>Вернуться ко входу</button>}{!isRecovery && <button onClick={() => onScreenChange(isRegister ? 'login' : 'register')}>{isRegister ? 'Уже есть аккаунт' : 'Создать аккаунт'}</button>}</div></section>
}

function AuthScreen({ onSuccess }: { onSuccess: () => void }) {
  const [screen, setScreen] = useState<AuthScreen>('login')
  return <main className="auth-page"><div className="auth-backdrop" /><div className="auth-frame-stage"><img className="auth-frame" src="/assets/8d5ea.png" alt="Резная деревянная рама" /><div className="auth-paper" /><div className="auth-brand"><span>ПРИ-</span><span>ДЕЛЕ</span></div><div className="auth-brand-rule" /><AuthForm screen={screen} onScreenChange={setScreen} onSuccess={onSuccess} /></div><aside className="auth-aside"><p>Вещи для дома, которые<br /><em>хочется оставить в семье.</em></p><span>примеряй · выбирай · живи</span></aside></main>
}

function RouteView({ route }: { route: Route }) {
  if (route === 'ar') return <div className="route-view route-ar"><p className="route-kicker">главное преимущество</p><h1>Посмотрите вещь<br />в своём пространстве</h1><button className="wood-button wood-button-primary">Запустить AR</button></div>
  return <div className="route-view"><p className="route-kicker">раздел приложения</p><h1>{routeTitles[route]}</h1><p className="route-description">Этот экран станет частью полного marketplace-flow на следующем шаге.</p></div>
}

function AppShell() {
  const [route, setRoute] = useState<Route>('home')
  return <main className="app-shell"><header className="shell-header"><div className="shell-mark">П</div><div><p>Добро пожаловать</p><strong>Приялье</strong></div><button className="header-action" aria-label="Уведомления">✦</button></header><RouteView route={route} /><BottomNavigation route={route} onNavigate={setRoute} /></main>
}

export default function App() {
  const [entered, setEntered] = useState(false)
  return entered ? <AppShell /> : <AuthScreen onSuccess={() => setEntered(true)} />
}
