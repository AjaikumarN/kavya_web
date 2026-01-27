/* ====================================
   KAVYA TRANSPORTS - CUSTOM ANIMATIONS
   Advanced JavaScript Animation Controller
   ==================================== */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize all animations
    initAOS();
    initCounterAnimation();
    initParallaxEffects();
    initScrollAnimations();
    initTruckAnimation();
    initRouteAnimation();
});

/* ====================================
   AOS (Animate On Scroll) Initialize
   ==================================== */
function initAOS() {
    if (typeof AOS !== 'undefined') {
        AOS.init({
            duration: 800,
            easing: 'ease-out-cubic',
            once: true,
            offset: 100,
            delay: 0,
            anchorPlacement: 'top-bottom'
        });
    }
}

/* ====================================
   COUNTER ANIMATION
   Animates numbers from 0 to target
   ==================================== */
function initCounterAnimation() {
    const counters = document.querySelectorAll('.counter');
    
    if (counters.length === 0) return;
    
    const observerOptions = {
        threshold: 0.5,
        rootMargin: '0px'
    };
    
    const counterObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                animateCounter(entry.target);
                counterObserver.unobserve(entry.target);
            }
        });
    }, observerOptions);
    
    counters.forEach(counter => {
        counterObserver.observe(counter);
    });
}

function animateCounter(element) {
    const target = parseInt(element.getAttribute('data-target')) || 0;
    const duration = 2000; // 2 seconds
    const startTime = performance.now();
    const startValue = 0;
    
    // Add plus sign if exists
    const plusSign = element.querySelector('.stat-plus');
    
    function updateCounter(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        // Easing function (ease-out)
        const easeOut = 1 - Math.pow(1 - progress, 3);
        const currentValue = Math.floor(startValue + (target - startValue) * easeOut);
        
        // Format number with commas
        element.textContent = formatNumber(currentValue);
        
        // Re-add plus sign if it exists
        if (plusSign) {
            element.appendChild(plusSign);
        }
        
        if (progress < 1) {
            requestAnimationFrame(updateCounter);
        } else {
            element.textContent = formatNumber(target);
            if (plusSign) {
                element.appendChild(plusSign);
            }
        }
    }
    
    requestAnimationFrame(updateCounter);
}

function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

/* ====================================
   PARALLAX EFFECTS
   ==================================== */
function initParallaxEffects() {
    const parallaxElements = document.querySelectorAll('[data-parallax]');
    
    if (parallaxElements.length === 0) return;
    
    window.addEventListener('scroll', () => {
        const scrolled = window.pageYOffset;
        
        parallaxElements.forEach(element => {
            const speed = parseFloat(element.getAttribute('data-parallax')) || 0.5;
            const offset = scrolled * speed;
            element.style.transform = `translateY(${offset}px)`;
        });
    }, { passive: true });
}

/* ====================================
   SCROLL-BASED ANIMATIONS
   ==================================== */
function initScrollAnimations() {
    // Reveal elements on scroll
    const revealElements = document.querySelectorAll('.reveal-on-scroll');
    
    if (revealElements.length === 0) return;
    
    const revealObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('revealed');
                revealObserver.unobserve(entry.target);
            }
        });
    }, { threshold: 0.1 });
    
    revealElements.forEach(el => revealObserver.observe(el));
    
    // Progress indicator
    updateScrollProgress();
    window.addEventListener('scroll', updateScrollProgress, { passive: true });
}

function updateScrollProgress() {
    const progressBar = document.querySelector('.scroll-progress');
    if (!progressBar) return;
    
    const windowHeight = window.innerHeight;
    const documentHeight = document.documentElement.scrollHeight - windowHeight;
    const scrolled = window.pageYOffset;
    const progress = (scrolled / documentHeight) * 100;
    
    progressBar.style.width = `${progress}%`;
}

/* ====================================
   TRUCK ANIMATION
   Animated truck in hero section
   ==================================== */
function initTruckAnimation() {
    const truck = document.querySelector('.truck-container');
    if (!truck) return;
    
    // Reset animation on scroll to top
    window.addEventListener('scroll', () => {
        if (window.pageYOffset < 100) {
            truck.style.animation = 'none';
            void truck.offsetWidth; // Trigger reflow
            truck.style.animation = null;
        }
    }, { passive: true });
}

/* ====================================
   ROUTE LINE ANIMATION
   SVG route drawing effect
   ==================================== */
function initRouteAnimation() {
    const routeLines = document.querySelectorAll('.route-line');
    
    if (routeLines.length === 0) return;
    
    const routeObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate');
            }
        });
    }, { threshold: 0.3 });
    
    routeLines.forEach(line => routeObserver.observe(line));
}

/* ====================================
   STAGGERED ANIMATION
   For lists and grids
   ==================================== */
function initStaggeredAnimations() {
    const staggerContainers = document.querySelectorAll('[data-stagger]');
    
    staggerContainers.forEach(container => {
        const children = container.children;
        const delay = parseFloat(container.getAttribute('data-stagger')) || 0.1;
        
        Array.from(children).forEach((child, index) => {
            child.style.animationDelay = `${index * delay}s`;
        });
    });
}

/* ====================================
   LOADING ANIMATION
   ==================================== */
function showLoading(element) {
    element.classList.add('loading');
}

function hideLoading(element) {
    element.classList.remove('loading');
}

/* ====================================
   TEXT TYPING ANIMATION
   ==================================== */
function typeText(element, text, speed = 50) {
    let index = 0;
    element.textContent = '';
    
    function type() {
        if (index < text.length) {
            element.textContent += text.charAt(index);
            index++;
            setTimeout(type, speed);
        }
    }
    
    type();
}

/* ====================================
   SCROLL TO TOP
   ==================================== */
function initScrollToTop() {
    const scrollBtn = document.querySelector('.scroll-to-top');
    if (!scrollBtn) return;
    
    window.addEventListener('scroll', () => {
        if (window.pageYOffset > 500) {
            scrollBtn.classList.add('visible');
        } else {
            scrollBtn.classList.remove('visible');
        }
    }, { passive: true });
    
    scrollBtn.addEventListener('click', () => {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
}

/* ====================================
   TIMELINE ANIMATION
   For About page highway timeline
   ==================================== */
function initTimelineAnimation() {
    const timelineItems = document.querySelectorAll('.timeline-item');
    const truck = document.querySelector('.timeline-truck');
    
    if (timelineItems.length === 0) return;
    
    const timelineObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('active');
                
                // Move truck to this position
                if (truck) {
                    const itemPos = entry.target.offsetTop;
                    truck.style.top = `${itemPos}px`;
                }
            }
        });
    }, { threshold: 0.5 });
    
    timelineItems.forEach(item => timelineObserver.observe(item));
}

/* ====================================
   MAP DOTS ANIMATION
   ==================================== */
function initMapAnimation() {
    const mapDots = document.querySelectorAll('.map-dot');
    
    mapDots.forEach((dot, index) => {
        dot.style.animationDelay = `${index * 0.2}s`;
    });
}

/* ====================================
   FORM ANIMATIONS
   ==================================== */
function initFormAnimations() {
    const inputs = document.querySelectorAll('.form-input, .form-textarea');
    
    inputs.forEach(input => {
        // Focus animation
        input.addEventListener('focus', () => {
            input.parentElement.classList.add('focused');
        });
        
        input.addEventListener('blur', () => {
            if (!input.value) {
                input.parentElement.classList.remove('focused');
            }
        });
        
        // Check if already has value (for autofill)
        if (input.value) {
            input.parentElement.classList.add('focused');
        }
    });
}

/* ====================================
   IMAGE LAZY LOADING WITH FADE
   ==================================== */
function initLazyImages() {
    const lazyImages = document.querySelectorAll('img[data-src]');
    
    if (lazyImages.length === 0) return;
    
    const imageObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.getAttribute('data-src');
                img.classList.add('loaded');
                imageObserver.unobserve(img);
            }
        });
    }, { rootMargin: '50px' });
    
    lazyImages.forEach(img => imageObserver.observe(img));
}

/* ====================================
   UTILITY FUNCTIONS
   ==================================== */

// Throttle function for performance
function throttle(func, limit) {
    let inThrottle;
    return function(...args) {
        if (!inThrottle) {
            func.apply(this, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// Debounce function
function debounce(func, wait) {
    let timeout;
    return function(...args) {
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(this, args), wait);
    };
}

// Check if element is in viewport
function isInViewport(element) {
    const rect = element.getBoundingClientRect();
    return (
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
        rect.right <= (window.innerWidth || document.documentElement.clientWidth)
    );
}

// Add animation class
function addAnimation(element, animationClass, duration = 1000) {
    element.classList.add(animationClass);
    setTimeout(() => {
        element.classList.remove(animationClass);
    }, duration);
}

/* ====================================
   EXPORT FOR MODULE USE
   ==================================== */
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        initAOS,
        initCounterAnimation,
        initParallaxEffects,
        initScrollAnimations,
        initTruckAnimation,
        initRouteAnimation,
        initTimelineAnimation,
        typeText,
        throttle,
        debounce
    };
}
