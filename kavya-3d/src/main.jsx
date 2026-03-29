import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import App from './App'
import About from './pages/About'
import Services from './pages/Services'
import Fleet from './pages/Fleet'
import Contact from './pages/Contact'
import Testimonials from './pages/Testimonials'
import Privacy from './pages/Privacy'
import Terms from './pages/Terms'
import Refund from './pages/Refund'
import GetQuote from './pages/GetQuote'
import './styles.css'
import './pages.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
    <Routes>
      <Route path="/" element={<App />} />
      <Route path="/about" element={<About />} />
      <Route path="/services" element={<Services />} />
      <Route path="/fleet" element={<Fleet />} />
      <Route path="/contact" element={<Contact />} />
      <Route path="/testimonials" element={<Testimonials />} />
      <Route path="/privacy" element={<Privacy />} />
      <Route path="/terms" element={<Terms />} />
      <Route path="/refund" element={<Refund />} />
      <Route path="/quote" element={<GetQuote />} />
    </Routes>
  </BrowserRouter>
)
