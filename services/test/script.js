function updateScale() {
    const baseFontSize = 16;
    const basePadding = 10;

    const screenWidth = window.innerWidth;
    const pixelRatio = window.devicePixelRatio || 1;

    let scaleFactor = Math.min(screenWidth / 375, 1.2); // iPhone SE
    scaleFactor *= pixelRatio > 1 ? 1.1 : 1;

    document.documentElement.style.setProperty('--dynamic-font-size', `${baseFontSize * scaleFactor}px`);
    document.documentElement.style.setProperty('--dynamic-padding', `${basePadding * scaleFactor}px`);
}

// Автоматическое скрытие хедера при прокрутке
let lastScrollY = window.scrollY;
window.addEventListener("scroll", () => {
    if (window.scrollY > lastScrollY) {
        document.body.classList.add("scrolled");
    } else {
        document.body.classList.remove("scrolled");
    }
    lastScrollY = window.scrollY;
});

// Реализация свайпов (например, для возврата назад)
document.addEventListener('touchstart', handleTouchStart, false);
document.addEventListener('touchmove', handleTouchMove, false);

let xDown = null;

function handleTouchStart(evt) {
    xDown = evt.touches[0].clientX;
}

function handleTouchMove(evt) {
    if (!xDown) return;

    let xUp = evt.touches[0].clientX;
    let xDiff = xDown - xUp;

    if (xDiff > 50) {
        console.log("Свайп влево");
    } else if (xDiff < -50) {
        console.log("Свайп вправо");
    }

    xDown = null;
}

// Долгое нажатие
document.querySelectorAll(".native-button").forEach(button => {
    let timer;
    button.addEventListener("mousedown", () => {
        timer = setTimeout(() => {
            alert("Долгое нажатие!");
        }, 800);
    });
    button.addEventListener("mouseup", () => clearTimeout(timer));
});

// Вибрация при нажатии
document.querySelectorAll(".native-button").forEach(button => {
    button.addEventListener("click", () => {
        if (navigator.vibrate) {
            navigator.vibrate(50);
        }
    });
});

// Обновляем масштаб при загрузке и изменении размера экрана
window.addEventListener('load', updateScale);
window.addEventListener('resize', updateScale);


document.addEventListener("DOMContentLoaded", () => {
    const grid = document.getElementById("grid");
    const totalButtons = 32; // Количество кнопок

    for (let i = 1; i <= totalButtons; i++) {
        const button = document.createElement("button");
        button.classList.add("grid-button");
        button.innerText = i; // Номер кнопки
        button.style.background = generateRandomGradient();
        
        button.addEventListener("click", () => {
            alert(`Вы нажали кнопку ${i}`);
        });

        grid.appendChild(button);
    }
});

// Генерация случайного градиента
function generateRandomGradient() {
    const colors = [
        "#ff7eb3", "#ff758c", "#ff7eb3", "#ffdf8c",
        "#ff9a8b", "#ff6a88", "#ffa07a", "#ff5f6d",
        "#8ec5fc", "#e0c3fc", "#d4fc79", "#96e6a1"
    ];
    const color1 = colors[Math.floor(Math.random() * colors.length)];
    const color2 = colors[Math.floor(Math.random() * colors.length)];
    
    return `linear-gradient(135deg, ${color1}, ${color2})`;
}




let deferredPrompt;

window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault();
    deferredPrompt = event;

    // Показываем кнопку установки
    const installButton = document.getElementById("installButton");
    if (installButton) {
        installButton.style.display = "block";
        installButton.addEventListener("click", () => {
            deferredPrompt.prompt();
            deferredPrompt.userChoice.then(choiceResult => {
                if (choiceResult.outcome === "accepted") {
                    console.log("PWA установлено!");
                }
                deferredPrompt = null;
            });
        });
    }
});

// Проверяем, установлено ли PWA
window.addEventListener("appinstalled", () => {
    console.log("PWA уже установлено");
    const installButton = document.getElementById("installButton");
    if (installButton) {
        installButton.style.display = "none";
    }
});
