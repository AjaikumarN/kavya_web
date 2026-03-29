import { useState } from 'react'
import { Link, useLocation } from 'react-router-dom'

export default function Header() {
  const [menuOpen, setMenuOpen] = useState(false)
  const { pathname } = useLocation()

  const links = [
    { to: '/', label: 'Home' },
    { to: '/about', label: 'About' },
    { to: '/services', label: 'Services' },
    { to: '/fleet', label: 'Fleet' },
    { to: '/testimonials', label: 'Clients' },
    { to: '/contact', label: 'Contact' },
  ]

  return (
    <header className="page-header">
      <div className="header-inner">
        <Link to="/" className="header-brand">
          <img src="/assets/logo.png" alt="Kavya Transports" className="header-logo" />
          <div className="header-brand-text">
            <span className="header-name">KAVYA</span>
            <span className="header-sub">TRANSPORTS</span>
          </div>
        </Link>

        <button
          className={`hamburger ${menuOpen ? 'hamburger--active' : ''}`}
          onClick={() => setMenuOpen(!menuOpen)}
          aria-label="Toggle menu"
        >
          <span /><span /><span />
        </button>

        <nav className={`header-nav ${menuOpen ? 'header-nav--open' : ''}`}>
          {links.map(l => (
            <Link
              key={l.to}
              to={l.to}
              className={`header-link ${pathname === l.to ? 'header-link--active' : ''}`}
              onClick={() => setMenuOpen(false)}
            >
              {l.label}
            </Link>
          ))}
          <Link to="/quote" className="header-cta" onClick={() => setMenuOpen(false)}>
            Get Quote
          </Link>
        </nav>
      </div>
    </header>
  )
}
