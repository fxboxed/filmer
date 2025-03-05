const openContact = document.querySelectorAll('.open-contact-form')
const contactForm = document.querySelectorAll('.contact-form')

openContact.forEach(btn => {
    btn.addEventListener('click', () => {
        contactForm.forEach(form => {
            form.classList.add('open-contact-form')
        })
    })
}) 