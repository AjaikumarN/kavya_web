import { Link } from 'react-router-dom'

export default function Footer() {
  return (
    <footer className="page-footer">
      <div className="footer-container">
        <div className="footer-grid">
          {/* Brand */}
          <div className="footer-brand">
            <div className="footer-logo-group">
              <img src="/assets/logo.png" alt="Kavya Transports" className="footer-logo-img" />
              <div>
                <span className="footer-brand-name">KAVYA TRANSPORTS</span>
                <span className="footer-tagline">Life on Wheels</span>
              </div>
            </div>
            <p className="footer-desc">
              Your trusted partner for reliable logistics and transport solutions across India. 
              Delivering excellence since 2004.
            </p>
          </div>

          {/* Quick Links */}
          <div className="footer-col">
            <h4>Quick Links</h4>
            <ul>
              <li><Link to="/">Home</Link></li>
              <li><Link to="/about">About Us</Link></li>
              <li><Link to="/services">Services</Link></li>
              <li><Link to="/fleet">Fleet</Link></li>
              <li><Link to="/testimonials">Clients</Link></li>
              <li><Link to="/contact">Contact</Link></li>
            </ul>
          </div>

          {/* Services */}
          <div className="footer-col">
            <h4>Services</h4>
            <ul>
              <li><Link to="/services">Road Transportation</Link></li>
              <li><Link to="/services">Air & Sea Cargo</Link></li>
              <li><Link to="/services">Warehousing</Link></li>
              <li><Link to="/services">3PL Solutions</Link></li>
              <li><Link to="/services">Manpower Services</Link></li>
            </ul>
          </div>

          {/* Contact */}
          <div className="footer-col footer-col-contact">
            <h4>Contact Us</h4>
            <ul>
              <li>
                <i className="fas fa-map-marker-alt" />
                <span>Door No.5/71C, Jyothivinayakar Temple Street,<br />Rediyarpatti, Tirunelveli – 627007</span>
              </li>
              <li>
                <i className="fas fa-phone" />
                <a href="tel:+919047244000">+91 90472 44000</a>
              </li>
              <li>
                <i className="fas fa-envelope" />
                <a href="mailto:info@kavyatransports.com">info@kavyatransports.com</a>
              </li>
            </ul>
          </div>
        </div>

        <div className="footer-bottom">
          <p>&copy; 2026 Kavya Transports. All rights reserved.</p>
          <div className="footer-legal">
            <Link to="/privacy">Privacy Policy</Link>
            <Link to="/terms">Terms of Service</Link>
            <Link to="/refund">Refund Policy</Link>
          </div>
        </div>
      </div>
    </footer>
  )
}
