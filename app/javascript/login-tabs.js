document.addEventListener("DOMContentLoaded", () => {
    const tabs = document.querySelectorAll(".login-tab")
    const roleField = document.querySelector("#login-role")
  
    const teacherFields = document.querySelector("#teacher-fields")
    const studentFields = document.querySelector("#student-fields")
  
    tabs.forEach(tab => {
      tab.addEventListener("click", () => {
        const role = tab.dataset.role
  
        // toggle tab active classes
        tabs.forEach(t => t.classList.remove("active"))
        tab.classList.add("active")
  
        // update hidden input
        roleField.value = role
  
        // toggle fieldsets
        if (role === "teacher") {
          teacherFields.classList.remove("hidden")
          studentFields.classList.add("hidden")
        } else {
          teacherFields.classList.add("hidden")
          studentFields.classList.remove("hidden")
        }
      })
    })
  })
  