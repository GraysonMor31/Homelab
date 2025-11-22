/* ----- Weather Widget Script ----- */
async function fetchWeather() {
    if (!navigator.geolocation) {
        document.getElementById('weather').innerText = 'Geolocation is not supported by your browser.';
        return;
    }

    navigator.geolocation.getCurrentPosition(async (position) => {
        const lat = position.coords.latitude;
        const lon = position.coords.longitude;

        try {
            let response = await fetch(`https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true`);
            if (!response.ok) {
                throw new Error('Network Response Was Not OK');
            }
            let data = await response.json();
            const weather = data.current_weather;
            document.getElementById('weather').innerText = `Temperature: ${weather.temperature}°F, Wind Speed: ${weather.windspeed} MPH`;
        } catch (error) {
            document.getElementById('weather').innerText = 'Failed to fetch weather data.';
            console.error('Error fetching weather data:', error);
        }
    }, (error) => {
        document.getElementById('weather').innerText = 'Unable to retrieve your location.';
    });
}

fetchWeather();