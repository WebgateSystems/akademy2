document.addEventListener("DOMContentLoaded", () => {
	const form = document.querySelector(".auth-form");
	if (!form) return;

	const submitButton = form.querySelector(".auth-submit");

	const fields = {
		first_name: document.getElementById("register_profile_form_first_name"),
		last_name: document.getElementById("register_profile_form_last_name"),
		email: document.getElementById("register_profile_form_email"),
		phone: document.getElementById("register_profile_form_phone"),
		marketing: document.getElementById("register_profile_form_marketing"),
	};

	const validators = {
		first_name: (v) => v.trim().length >= 2,
		last_name: (v) => v.trim().length >= 2,
		birthdate: (v) => {
			const pattern = /^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[0-2])\.(19|20)\d{2}$/;
			if (!pattern.test(v)) return false;

			const [d, m, y] = v.split(".").map(Number);
			const date = new Date(y, m - 1, d);
			return (
				date.getDate() === d &&
				date.getMonth() === m - 1 &&
				date.getFullYear() === y
			);
		},
		email: (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
		phone: (v) => /^\+?[0-9\s-]{10,}$/.test(v.trim()),
		marketing: (_, input) => input.checked === true,
	};

	function isFormValid() {
		return Object.entries(fields).every(([key, input]) => {
			if (!input) return false;
			const value = input.type === "checkbox" ? input.checked : input.value;
			return validators[key](value, input);
		});
	}

	function toggleButton() {
		const valid = isFormValid();
		submitButton.disabled = !valid;
		submitButton.classList.toggle("auth-submit--disabled", !valid);
	}

	// add listeners
	Object.entries(fields).forEach(([key, input]) => {
		if (!input) return;
		const eventName = input.type === "checkbox" ? "change" : "input";
		input.addEventListener(eventName, toggleButton);
	});

	form.addEventListener("submit", (e) => {
		if (!isFormValid()) e.preventDefault();
	});

	// initial state
	toggleButton();
});
