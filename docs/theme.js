function dark_theme() {
    document.body.classList.add('dark');
    localStorage.theme = 'dark';
    document.getElementById('toggle-theme').innerText = 'Light Theme';
}

function light_theme() {
    document.body.classList.remove('dark');
    localStorage.theme = 'light';
    document.getElementById('toggle-theme').innerText = 'Dark Theme';
}

function toggle_theme() {
    if (localStorage.theme === 'dark') {
        light_theme();
    } else {
        dark_theme();
    }
}
