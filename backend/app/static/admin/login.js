/* global document, localStorage, location, fetch */
(function () {
  const form = document.getElementById("f");
  const phoneEl = document.getElementById("phone");
  const passEl = document.getElementById("pass");
  const errEl = document.getElementById("error");

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    errEl.textContent = "";
    const r = await fetch("/api/v1/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        phone: phoneEl.value,
        password: passEl.value,
      }),
    });
    if (r.ok) {
      const d = await r.json();
      localStorage.setItem("at", d.access_token);
      location.assign("/admin");
    } else {
      errEl.textContent = "Noto'g'ri telefon yoki parol";
    }
  });
})();
