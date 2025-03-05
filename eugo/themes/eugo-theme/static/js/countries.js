
const countryLinks = document.querySelectorAll('.country-link');
const dropdownButtons = document.querySelectorAll('.open-country-dropdown');
const countryLists = document.querySelectorAll('.country-list');
const bannerItems = document.querySelectorAll('.banner-items');
window.onload = function() {

    // hide dropdown buttons if not on homepage
    if(window.location.href == 'http://localhost:1313/'  || window.location.href == 'http://localhost:1313/#navbar' || window.location.href == 'https://eugo.uk/' || window.location.href == 'https://eugo.uk/#navbar' || window.location.href == 'https://eugo.uk/#footer' )  {
        dropdownButtons.forEach(button => {
            button.style.display = 'block';
        });
    }
    else{
        dropdownButtons.forEach(button => {
            button.style.display = 'none';
        });
    }
    // if(window.location.href == 'http://localhost:1313/'  || window.location.href == 'http://localhost:1313/#navbar' || window.location.href == 'https://eugo.uk/' || window.location.href == 'https://eugo.uk/#navbar' || window.location.href == 'https://eugo.uk/#footer' )  {
    //     dropdownButtons.forEach(button => {
    //         button.innerHTML = 'Countries';
    //     });
    // }
    // else{
    //     dropdownButtons.forEach(button => {
    //         button.innerHTML = 'Top Destinations';
    //     });
    // }


    // truncate country links if length is greater than 8
    countryLinks.forEach(link => {
        if (link.innerHTML.length > 8) {
            link.innerHTML = link.innerHTML.substring(0, 8) + '...';
        }
    });

};

    //add eventListener to all buttons with classname 'open-country-dropdown'. when clicked, toggle show / hide elements with classname country-list

    // if (dropdownButtons.length > 0 && countryLists.length > 0) {
        dropdownButtons.forEach(button => {

            button.addEventListener('click', () => {
                //console.log('open clicked stat');

                bannerItems.forEach(banner => {
                    banner.classList.add('hide-banner-items');
                });
                countryLists.forEach(list => {
                    list.classList.add('show-country-list');

                });
            });
        });
    // }

    //add eventListener to all buttons with classname 'close-country-dropdown'. when clicked, toggle show / hide elements with classname country-list
    const closeDropdownButtons = document.querySelectorAll('.close-country-dropdown');

    // if (closeDropdownButtons.length > 0 && countryLists.length > 0) {
        closeDropdownButtons.forEach(button => {
            button.addEventListener('click', () => {
                //console.log('close clicked');
                countryLists.forEach(list => {
                    list.classList.remove('show-country-list');
                });

                bannerItems.forEach(banner => {
                    banner.classList.remove('hide-banner-items');
                });
            });
        });
    // }
    //sort country links alphabetically
    let sortedNavItems = Array.from(countryLinks).sort((a, b) => a.innerHTML.toLowerCase().localeCompare(b.innerHTML.toLowerCase())); // Sort items alphabetically
    sortedNavItems.forEach(item => document.getElementById('topnav').appendChild(item));
