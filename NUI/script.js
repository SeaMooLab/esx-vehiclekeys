const container = document.querySelector('.container');
let dragging = false;
let dragOffsetX = 0;
let dragOffsetY = 0;

function postAction(action) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({}),
    });
    container.style.display = 'none';
}

window.addEventListener('message', (event) => {
    if (event.data?.casemenue === 'open') {
        container.style.display = 'block';
    }
});

document.addEventListener('keyup', (event) => {
    if (event.key !== 'Escape') return;
    postAction('closui');
});

document.addEventListener('click', (event) => {
    const button = event.target.closest('[data-action]');
    if (!button) return;
    postAction(button.dataset.action);
});

container.addEventListener('mousedown', (event) => {
    dragging = true;
    dragOffsetX = event.clientX - container.offsetLeft;
    dragOffsetY = event.clientY - container.offsetTop;
});

document.addEventListener('mousemove', (event) => {
    if (!dragging) return;
    container.style.left = `${event.clientX - dragOffsetX}px`;
    container.style.top = `${event.clientY - dragOffsetY}px`;
});

document.addEventListener('mouseup', () => {
    dragging = false;
});
