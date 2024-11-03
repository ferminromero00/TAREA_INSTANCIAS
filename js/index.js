// Carrusel de imágenes
const carousel = document.getElementById('carousel');
const images = carousel.getElementsByTagName('img');
let currentImage = 0;

/**
 * Cambia la imagen actual del carrusel a la siguiente. Modficar comentario
 * Remueve la clase 'active' de la imagen actual y la aplica a la siguiente imagen.
 */
function changeImage() {
    images[currentImage].classList.remove('active');
    currentImage = (currentImage + 1) % images.length;
    images[currentImage].classList.add('active');
}

// Cambia la imagen del carrusel cada 5 segundos
setInterval(changeImage, 5000);

// Formulario de contacto
const form = document.getElementById('contact-form');

/**
 * Maneja el envío del formulario de contacto.
 * Verifica que todos los campos estén llenos antes de mostrar un mensaje de confirmación
 * o una advertencia.
 * 
 * @param {Event} e - El evento de envío del formulario que recoge datos.
 */
function handleFormSubmit(e) {
    e.preventDefault();
    const nombre = document.getElementById('nombre').value;
    const email = document.getElementById('email').value;
    const mensaje = document.getElementById('mensaje').value;

    if (nombre && email && mensaje) {
        alert('Gracias por contactarnos. Le responderemos pronto.');
        form.reset();
    } else {
        alert('Por favor, rellene todos los campos');
    }
}

// Añade el listener de envío al formulario de contacto
form.addEventListener('submit', handleFormSubmit);

// Cambio de tema
const themeToggle = document.getElementById('theme-toggle');

/**
 * Alterna entre el tema claro y oscuro de la página.
 * Cambia el texto del botón según el tema actual.
 */
function toggleTheme() {
    document.body.classList.toggle('dark-theme');
    themeToggle.textContent = document.body.classList.contains('dark-theme') ? '☀️' : '🌙';
}

// Añade el listener de clic para cambiar el tema
themeToggle.addEventListener('click', toggleTheme);
