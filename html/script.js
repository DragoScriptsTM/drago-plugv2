let cart = {}

window.addEventListener("message", function (event) {
    const data = event.data

    if (data.action === "open") {
        document.querySelector(".container").style.display = "block"
        document.body.classList.add("menu-open")
        loadItems(data.items)

        if (data.stats) {
            updateStatsUI(data.stats.personal ? data.stats : { leaderboard: [], personal: { sales: 0, earned: 0 } })
        }
    } else if (data.action === "close") {
        closeUI()
    } else if (data.action === "statsData") {
        updateStatsUI(data.data)
    }
})

function loadItems(items) {
    const list = document.getElementById("item-list")
    list.innerHTML = ""
    items.forEach(item => {
        const div = document.createElement("div")
        div.className = "item"
        div.innerHTML = `
            <img src="nui://qb-inventory/html/images/${item.image}" style="width:64px; height:64px">
            <span>${item.label}</span>
            <span>€${item.price}</span>
            <div class="amount-selector">
                <button class="qty-btn left" onclick="decreaseQuantity('${item.name}')">−</button>
                <input type="number" min="1" max="${item.amount}" value="1" id="qty-${item.name}" oninput="validateQuantity('${item.name}', ${item.amount})">
                <button class="qty-btn right" onclick="increaseQuantity('${item.name}', ${item.amount})">+</button>
            </div>

            <button onclick="addToCart('${item.name}', '${item.label}', ${item.price}, ${item.amount})">Toevoegen</button>
        `
        list.appendChild(div)
    })
}

function increaseQuantity(name, max) {
    const input = document.getElementById(`qty-${name}`)
    let current = parseInt(input.value)
    if (current < max) {
        input.value = current + 1
    }
}

function decreaseQuantity(name) {
    const input = document.getElementById(`qty-${name}`)
    let current = parseInt(input.value)
    if (current > 1) {
        input.value = current - 1
    }
}

function validateQuantity(name, max) {
    const input = document.getElementById(`qty-${name}`)
    let val = parseInt(input.value)

    if (isNaN(val) || val < 1) {
        input.value = 1
    } else if (val > max) {
        input.value = max
    } else {
        input.value = val
    }
}

function addToCart(name, label, price, maxAmount) {
    const amount = parseInt(document.getElementById("qty-" + name).value)
    if (!amount || amount < 1 || amount > maxAmount) return

    cart[name] = { name, label, price, amount }
    updateCart()
}

function updateCart() {
    const container = document.getElementById("cart-items")
    container.innerHTML = ""
    let total = 0

    Object.values(cart).forEach(item => {
        total += item.amount * item.price
        container.innerHTML += `<div>${item.amount}x ${item.label} - €${item.amount * item.price}</div>`
    })

    document.getElementById("total-price").innerText = `€${total}`
}

function submitCart() {
    fetch(`https://${GetParentResourceName()}/sellItems`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ items: Object.values(cart) })
    })
    cart = {}
    updateCart()
    closeUI()
}

function closeUI() {
    document.querySelector(".container").style.display = "none"
    document.body.classList.remove("menu-open")
    fetch(`https://${GetParentResourceName()}/close`, { method: "POST" })
}

function updateStatsUI(data) {
    const leaderboardList = document.getElementById("leaderboard-list")
    leaderboardList.innerHTML = ""

    if (data.leaderboard && data.leaderboard.length > 0) {
        data.leaderboard.forEach((entry, index) => {
            leaderboardList.innerHTML += `<li>#${index + 1} ${entry.playerName || entry.citizenid} - €${entry.earned}</li>`
        })
    } else {
        leaderboardList.innerHTML = "<li>Geen data beschikbaar</li>"
    }

    document.getElementById("player-sales").innerText = data.personal.sales || 0
    document.getElementById("player-profit").innerText = data.personal.earned || 0
}
