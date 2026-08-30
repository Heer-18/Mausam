// ── PERSONA DATA ──
const personaData = {
    health: {
        icon: 'fa-heartbeat',
        title: 'Health-Conscious',
        badge: 'Allergy & Skin',
        desc: 'AQI, pollen, UV, humidity',
        attributes: [
            { label: 'AQI', value: '42', unit: '', sub: 'Good · PM2.5 12' },
            { label: 'Pollen (Grass)', value: 'Low', unit: '', sub: '8 grains/m³' },
            { label: 'Pollen (Tree)', value: 'Moderate', unit: '', sub: '22 grains/m³' },
            { label: 'UV Index', value: '6', unit: '', sub: 'High · SPF 30+' },
            { label: 'Humidity', value: '84%', unit: '', sub: 'Skin sensitivity' },
            { label: 'Air Quality', value: 'Good', unit: '', sub: 'Safe outdoor' },
        ],
        suggestion: '✅ AQI is good today. UV is high — wear sunscreen and a hat. Pollen is low, great for outdoor walks.'
    },
    fitness: {
        icon: 'fa-running',
        title: 'Outdoor Fitness',
        badge: 'Workout Planner',
        desc: 'Sunrise, best hours, wind, heat',
        attributes: [
            { label: 'Sunrise', value: '6:32 AM', unit: '', sub: 'Sunset 7:15 PM' },
            { label: 'Best Running', value: '6 – 8 AM', unit: '', sub: 'Feels 26°' },
            { label: 'Wind Speed', value: '8', unit: 'km/h', sub: 'SSW · Light' },
            { label: 'Wind Gusts', value: '14', unit: 'km/h', sub: 'Comfortable' },
            { label: 'Heat Index', value: '33°', unit: '', sub: 'Moderate' },
            { label: 'Running Score', value: '85/100', unit: '', sub: 'Great' },
        ],
        suggestion: '🏃 Perfect running window from 6–8 AM with light breeze. Heat is moderate — stay hydrated.'
    },
    beach: {
        icon: 'fa-umbrella-beach',
        title: 'Beachgoers & Surfers',
        badge: 'Safe Beach',
        desc: 'Sea, tide, waves, water temp',
        attributes: [
            { label: 'Sea State', value: 'Calm', unit: '', sub: 'Swell 0.3m' },
            { label: 'High Tide', value: '2:30 PM', unit: '', sub: 'Low 8:45 PM' },
            { label: 'Wave Height', value: '0.5', unit: 'm', sub: 'Gentle' },
            { label: 'Water Temp', value: '26°', unit: '', sub: 'Comfortable' },
            { label: 'Surf Quality', value: 'Fair', unit: '', sub: 'Small waves' },
            { label: 'Rip Risk', value: 'Low', unit: '', sub: 'Safe' },
        ],
        suggestion: '🏄 Great beach day! Calm seas and warm water. Tide rising at 2:30 PM — swim safely.'
    },
    travel: {
        icon: 'fa-plane',
        title: 'Travelers',
        badge: 'Saved: 3 cities',
        desc: 'Destinations, alerts, packing',
        attributes: [
            { label: 'Mumbai', value: '31°', unit: '', sub: 'Clear · Pack light' },
            { label: 'Delhi', value: '34°', unit: '', sub: 'Haze · Carry mask' },
            { label: 'London', value: '18°', unit: '', sub: 'Rain · Pack coat' },
            { label: 'Flight Risk', value: 'Low', unit: '', sub: 'On time' },
            { label: 'Packing Tip', value: 'Raincoat', unit: '', sub: 'For London' },
            { label: 'Weather Alert', value: 'None', unit: '', sub: 'Smooth' },
        ],
        suggestion: '🧳 London rain expected — pack a raincoat and umbrella. Mumbai & Delhi are warm and clear.'
    },
    farm: {
        icon: 'fa-seedling',
        title: 'Farmers & Gardeners',
        badge: 'Crop Health',
        desc: 'Soil, rain, frost, planting',
        attributes: [
            { label: 'Soil Moisture', value: '42%', unit: '', sub: 'Slightly dry' },
            { label: 'Rain Prediction', value: '30%', unit: '', sub: 'Tonight' },
            { label: 'Frost Alert', value: 'None', unit: '', sub: 'Safe planting' },
            { label: 'Growing Days', value: '22°', unit: 'GDD', sub: 'Good growth' },
            { label: 'Planting Guide', value: 'Tomato, Basil', unit: '', sub: 'Ideal' },
            { label: 'Crop Risk', value: 'Low', unit: '', sub: 'Favorable' },
        ],
        suggestion: '🌱 Soil is a bit dry — water deeply today. No frost risk, ideal for transplanting tomatoes.'
    },
    commute: {
        icon: 'fa-car',
        title: 'Commuters',
        badge: 'Traffic + Weather',
        desc: 'Traffic, visibility, alerts',
        attributes: [
            { label: 'Traffic Flow', value: 'Moderate', unit: '', sub: '12 min delay' },
            { label: 'Visibility', value: '10', unit: 'km', sub: 'Clear' },
            { label: 'Storm Alert', value: 'None', unit: '', sub: 'Safe' },
            { label: 'Fog Alert', value: 'None', unit: '', sub: 'Clear' },
            { label: 'Road Safety', value: 'Good', unit: '', sub: 'Dry' },
            { label: 'Transit Status', value: 'On time', unit: '', sub: 'No delays' },
        ],
        suggestion: '🚗 Traffic is moderate — allow extra 10–15 min. No fog or storm warnings. Roads are dry.'
    },
    events: {
        icon: 'fa-calendar-check',
        title: 'Event Planners',
        badge: 'Outdoor Events',
        desc: 'Outlook, rain, comfort, wind',
        attributes: [
            { label: '7-Day Outlook', value: 'Fair', unit: '', sub: 'Mostly sunny' },
            { label: 'Rain Chance', value: '25%', unit: '', sub: 'Saturday PM' },
            { label: 'Comfort Index', value: '78°F', unit: '', sub: 'Excellent' },
            { label: 'Wind Conditions', value: '10', unit: 'km/h', sub: 'Pleasant' },
            { label: 'Event Risk', value: 'Low', unit: '', sub: 'Good outdoor' },
            { label: 'Sunset Time', value: '7:15 PM', unit: '', sub: 'Golden hour' },
        ],
        suggestion: '🎉 Saturday has 25% rain chance — have a backup plan. Comfort index is excellent.'
    },
    parents: {
        icon: 'fa-family',
        title: 'Parents & Families',
        badge: 'School Commute',
        desc: 'School route, rain, warnings',
        attributes: [
            { label: 'School Route', value: 'Clear', unit: '', sub: 'No delays' },
            { label: 'Rain Alert', value: 'None', unit: '', sub: 'Dry' },
            { label: 'Severe Warnings', value: 'None', unit: '', sub: 'Safe' },
            { label: 'UV Index', value: '6', unit: '', sub: 'Sunblock for kids' },
            { label: 'After-School', value: 'Good', unit: '', sub: 'Playground safe' },
            { label: 'Air Quality', value: 'Good', unit: '', sub: 'Safe' },
        ],
        suggestion: '👨‍👩‍👧‍👦 Perfect school commute. Apply sunscreen on kids — UV is high at noon.'
    },
    construction: {
        icon: 'fa-hard-hat',
        title: 'Construction & Work',
        badge: 'Safety First',
        desc: 'Rain, wind, lightning, heat',
        attributes: [
            { label: 'Rain Alert', value: 'None', unit: '', sub: 'Dry' },
            { label: 'Wind Gusts', value: '25', unit: 'km/h', sub: 'Secure materials' },
            { label: 'Lightning Risk', value: 'None', unit: '', sub: 'Safe' },
            { label: 'Heat Warning', value: 'Moderate', unit: '', sub: 'Take breaks' },
            { label: 'Work Safety', value: 'Good', unit: '', sub: 'Proceed' },
            { label: 'Visibility', value: '10', unit: 'km', sub: 'Clear' },
        ],
        suggestion: '⛑️ Wind gusts up to 25 km/h — secure loose materials. Heat is moderate, take hydration breaks.'
    }
};

// ── COMMON ATTRIBUTES ──
const commonAttributes = [
    { label: 'Humidity', value: '84%', sub: 'Comfortable' },
    { label: 'Wind', value: '8 km/h', sub: 'SSW · Light' },
    { label: 'AQI', value: '42', sub: 'Good · PM2.5 12' },
    { label: 'UV Index', value: '6', sub: 'High · SPF 30+' },
    { label: 'Sunrise', value: '6:32 AM', sub: 'Sunset 7:15 PM' },
    { label: 'Visibility', value: '10 km', sub: 'Clear' },
    { label: 'Precip.', value: '25%', sub: 'Chance rain' },
    { label: 'Pressure', value: '1012 hPa', sub: 'Stable' },
    { label: 'Dew Point', value: '22°', sub: 'Comfortable' },
];

const personaKeys = ['general', 'health', 'fitness', 'beach', 'travel', 'farm', 'commute', 'events', 'parents', 'construction'];
const personaDisplay = {
    general: { icon: 'fa-user', label: 'General', desc: 'Balanced' },
    health: { icon: 'fa-heartbeat', label: 'Health', desc: 'Allergy & Skin' },
    fitness: { icon: 'fa-running', label: 'Fitness', desc: 'Workout' },
    beach: { icon: 'fa-umbrella-beach', label: 'Beach', desc: 'Surf & Swim' },
    travel: { icon: 'fa-plane', label: 'Travel', desc: 'Destinations' },
    farm: { icon: 'fa-seedling', label: 'Farm', desc: 'Crop Health' },
    commute: { icon: 'fa-car', label: 'Commute', desc: 'Traffic & Alerts' },
    events: { icon: 'fa-calendar-check', label: 'Events', desc: 'Outdoor Plans' },
    parents: { icon: 'fa-family', label: 'Family', desc: 'School & Safety' },
    construction: { icon: 'fa-hard-hat', label: 'Work', desc: 'Safety First' },
};

// ── PARAMETER DEFINITIONS ──
const allParams = [
    // General (only 4!)
    { id: 'aqi', label: 'AQI', icon: 'fa-smog', cat: 'general', active: true },
    { id: 'uv', label: 'UV Index', icon: 'fa-sun', cat: 'general', active: true },
    { id: 'humidity', label: 'Humidity', icon: 'fa-tint', cat: 'general', active: true },
    { id: 'feelslike', label: 'Feels Like', icon: 'fa-thermometer', cat: 'general', active: true },

    // Health
    { id: 'pollen', label: 'Pollen count', icon: 'fa-allergies', cat: 'health', active: false },
    { id: 'pm25', label: 'PM2.5/PM10', icon: 'fa-microscope', cat: 'health', active: false },
    { id: 'mold', label: 'Mold risk', icon: 'fa-biohazard', cat: 'health', active: false },

    // Fitness
    { id: 'heatstress', label: 'Heat stress', icon: 'fa-temperature-high', cat: 'fitness', active: false },
    { id: 'workout', label: 'Best workout time', icon: 'fa-clock', cat: 'fitness', active: false },
    { id: 'sunexposure', label: 'Sun exposure duration', icon: 'fa-sun', cat: 'fitness', active: false },
    { id: 'comfort', label: 'Activity comfort score', icon: 'fa-smile', cat: 'fitness', active: false },

    // Beach
    { id: 'waveheight', label: 'Wave height', icon: 'fa-water', cat: 'beach', active: false },
    { id: 'tide', label: 'Tide timings', icon: 'fa-clock', cat: 'beach', active: false },
    { id: 'seatemp', label: 'Sea temperature', icon: 'fa-thermometer-half', cat: 'beach', active: false },
    { id: 'ripcurrent', label: 'Rip-current risk', icon: 'fa-exclamation-triangle', cat: 'beach', active: false },

    // Travel
    { id: 'routeweather', label: 'Weather along route', icon: 'fa-route', cat: 'travel', active: false },
    { id: 'flightrisk', label: 'Flight-weather risk', icon: 'fa-plane', cat: 'travel', active: false },
    { id: 'packing', label: 'Packing recommendation', icon: 'fa-suitcase', cat: 'travel', active: false },

    // Family
    { id: 'schoolrisk', label: 'School commute risk', icon: 'fa-school', cat: 'parents', active: false },
    { id: 'playground', label: 'Playground suitability', icon: 'fa-park', cat: 'parents', active: false },
    { id: 'airqualityrisk', label: 'Air-quality risk', icon: 'fa-smog', cat: 'parents', active: false },

    // Farmer
    { id: 'soilmoisture', label: 'Soil moisture', icon: 'fa-tint', cat: 'farm', active: false },
    { id: 'frostrisk', label: 'Frost risk', icon: 'fa-snowflake', cat: 'farm', active: false },
    { id: 'irrigation', label: 'Irrigation recommendation', icon: 'fa-tint', cat: 'farm', active: false },
    { id: 'croprisk', label: 'Crop/plant risk', icon: 'fa-seedling', cat: 'farm', active: false },

    // Commuter
    { id: 'roadflood', label: 'Road-flood risk', icon: 'fa-car-crash', cat: 'commute', active: false },
    { id: 'crosswind', label: 'Crosswind risk', icon: 'fa-wind', cat: 'commute', active: false },
    { id: 'fogrisk', label: 'Fog risk', icon: 'fa-smog', cat: 'commute', active: false },

    // Event
    { id: 'rainprob', label: 'Rain probability', icon: 'fa-percent', cat: 'events', active: false },
    { id: 'rainfree', label: 'Rain-free window', icon: 'fa-cloud-sun', cat: 'events', active: false },
    { id: 'outdoorcomfort', label: 'Outdoor comfort index', icon: 'fa-smile', cat: 'events', active: false },
    { id: 'windgustrisk', label: 'Wind-gust risk', icon: 'fa-wind', cat: 'events', active: false },
    { id: 'eventconfidence', label: 'Weather confidence', icon: 'fa-check-circle', cat: 'events', active: false },
];

// ── STATE ──
let selectedPersona = localStorage.getItem('weatherAwarePersona') || 'general';
let tempSelected = selectedPersona;
let currentTab = 'forecast';
let currentCategory = null;
let paramState = loadParamState();

// ── DOM REFS ──
const overlay = document.getElementById('settingsOverlay');
const personaGrid = document.getElementById('personaGrid');
const saveBtn = document.getElementById('savePersonaBtn');
const closeBtn = document.getElementById('closeOverlay');
const settingsIcon = document.getElementById('settingsIcon');
const changeLink = document.getElementById('changePersonaLink');
const selectedLabel = document.getElementById('selectedLabel');
const overlayTitle = document.getElementById('overlayTitle');
const overlaySub = document.getElementById('overlaySub');
const personaContent = document.getElementById('personaContent');
const statsGrid = document.getElementById('statsGrid');
const chatMessages = document.getElementById('chatMessages');
const chatInput = document.getElementById('chatInput');
const sendBtn = document.getElementById('sendBtn');
const notifPopup = document.getElementById('notifPopup');
const notifClose = document.getElementById('notifClose');
const bellIcon = document.getElementById('bellIcon');
const plusIcon = document.getElementById('plusIcon');
const paramPanel = document.getElementById('paramPanel');
const paramList = document.getElementById('paramList');
const paramClose = document.getElementById('paramClose');
const paramReset = document.getElementById('paramReset');
const paramSave = document.getElementById('paramSave');
const paramSearch = document.getElementById('paramSearch');
const paramStats = document.getElementById('paramStats');
const paramBack = document.getElementById('paramBack');
const paramPanelTitle = document.getElementById('paramPanelTitle');
const paramCategoryView = document.getElementById('paramCategoryView');
const paramParameterView = document.getElementById('paramParameterView');

// ── CATEGORIES ──
const categories = ['general', 'health', 'fitness', 'beach', 'travel', 'farm', 'commute', 'events', 'parents', 'construction'];

// ── PARAM STATE ──
function loadParamState() {
    const saved = localStorage.getItem('mausamParams');
    if (saved) {
        try {
            const parsed = JSON.parse(saved);
            allParams.forEach(p => {
                if (parsed[p.id] !== undefined) p.active = parsed[p.id];
            });
            return parsed;
        } catch (e) { /* ignore */ }
    }
    // Defaults: only aqi, uv, humidity, feelslike on
    allParams.forEach(p => p.active = false);
    const defaults = ['aqi', 'uv', 'humidity', 'feelslike'];
    allParams.forEach(p => {
        if (defaults.includes(p.id)) p.active = true;
    });
    const state = {};
    allParams.forEach(p => { state[p.id] = p.active; });
    return state;
}

function saveParamState() {
    const state = {};
    allParams.forEach(p => { state[p.id] = p.active; });
    localStorage.setItem('mausamParams', JSON.stringify(state));
    paramState = state;
    updateParamStats();
}

function updateParamStats() {
    const count = allParams.filter(p => p.active).length;
    paramStats.textContent = `${count} of ${allParams.length} parameters active`;
}

// ── CATEGORY VIEW ──
function showCategories() {
    paramCategoryView.style.display = 'block';
    paramParameterView.style.display = 'none';
    paramBack.style.display = 'none';
    paramPanelTitle.textContent = 'Categories';
    renderCategories();
}

function renderCategories() {
    let html = '<div class="category-grid">';
    categories.forEach(cat => {
        const info = personaDisplay[cat];
        const count = allParams.filter(p => p.cat === cat && p.active).length;
        const total = allParams.filter(p => p.cat === cat).length;
        html += `
            <div class="category-item" onclick="showParameters('${cat}')">
                <i class="fas ${info.icon}"></i>
                <div class="c-name">${info.label}</div>
                <div class="c-desc">${info.desc}</div>
                <div class="c-count">${count}/${total} active</div>
            </div>
        `;
    });
    html += '</div>';
    paramCategoryView.innerHTML = html;
}

// ── PARAMETER VIEW ──
function showParameters(category) {
    currentCategory = category;
    paramCategoryView.style.display = 'none';
    paramParameterView.style.display = 'block';
    paramBack.style.display = 'block';
    const info = personaDisplay[category];
    paramPanelTitle.textContent = info ? info.label : category.charAt(0).toUpperCase() + category.slice(1);
    renderParams('', category);
}

function renderParams(filter = '', category = currentCategory) {
    const search = filter.toLowerCase().trim();
    const filtered = allParams.filter(p => {
        if (category && p.cat !== category) return false;
        const match = p.label.toLowerCase().includes(search) || p.cat.toLowerCase().includes(search);
        return match;
    });
    let html = '';
    const sorted = filtered.sort((a, b) => {
        const aActive = a.active ? 1 : 0;
        const bActive = b.active ? 1 : 0;
        if (aActive !== bActive) return bActive - aActive;
        return a.label.localeCompare(b.label);
    });
    sorted.forEach(p => {
        html += `
            <div class="param-item" data-id="${p.id}">
                <div class="p-left">
                    <i class="fas ${p.icon}"></i>
                    ${p.label}
                    <span class="p-cat-tag">${p.cat}</span>
                </div>
                <div class="p-toggle ${p.active ? 'active' : ''}" onclick="toggleParam('${p.id}')"></div>
            </div>
        `;
    });
    paramList.innerHTML = html || '<div style="color:rgba(255,255,255,0.2);text-align:center;padding:20px;">No parameters in this category</div>';
    updateParamStats();
}

function toggleParam(id) {
    const p = allParams.find(x => x.id === id);
    if (p) {
        p.active = !p.active;
        renderParams(paramSearch.value, currentCategory);
    }
}

function resetParams() {
    allParams.forEach(p => p.active = false);
    const defaults = ['aqi', 'uv', 'humidity', 'feelslike'];
    allParams.forEach(p => {
        if (defaults.includes(p.id)) p.active = true;
    });
    renderParams(paramSearch.value, currentCategory);
    if (paramCategoryView.style.display !== 'none') {
        renderCategories();
    }
}

function saveParams() {
    saveParamState();
    closeParamPanel();
    renderStats();
    if (paramCategoryView.style.display !== 'none') {
        renderCategories();
    }
}

function openParamPanel() {
    showCategories();
    paramPanel.classList.add('active');
}

function closeParamPanel() {
    paramPanel.classList.remove('active');
}

// ── RENDER STATS GRID ──
function renderStats() {
    const active = allParams.filter(p => p.active);
    if (active.length === 0) {
        statsGrid.innerHTML = `<div style="grid-column:1/-1;text-align:center;color:rgba(255,255,255,0.2);padding:20px;">No active parameters. Tap + to add.</div>`;
        return;
    }
    const valueMap = {
        aqi: { value: '42', sub: 'Good' },
        uv: { value: '6', sub: 'High' },
        humidity: { value: '84%', sub: 'High' },
        feelslike: { value: '33°', sub: 'Humid' },
        pollen: { value: 'Low', sub: '8 grains' },
        pm25: { value: '12 µg/m³', sub: 'Good' },
        mold: { value: 'Low', sub: 'Safe' },
        heatstress: { value: 'Moderate', sub: 'Caution' },
        workout: { value: '6–8 AM', sub: 'Best' },
        sunexposure: { value: '45 min', sub: 'Safe' },
        comfort: { value: '85/100', sub: 'Great' },
        waveheight: { value: '0.5 m', sub: 'Calm' },
        tide: { value: '2:30 PM', sub: 'High' },
        seatemp: { value: '26°', sub: 'Warm' },
        ripcurrent: { value: 'Low', sub: 'Safe' },
        routeweather: { value: 'Clear', sub: 'Good' },
        flightrisk: { value: 'Low', sub: 'On time' },
        packing: { value: 'Raincoat', sub: 'London' },
        schoolrisk: { value: 'Low', sub: 'Safe' },
        playground: { value: 'Good', sub: 'Open' },
        airqualityrisk: { value: 'Low', sub: 'Safe' },
        soilmoisture: { value: '42%', sub: 'Dry' },
        frostrisk: { value: 'None', sub: 'Safe' },
        irrigation: { value: 'Water', sub: 'Today' },
        croprisk: { value: 'Low', sub: 'Favorable' },
        roadflood: { value: 'None', sub: 'Dry' },
        crosswind: { value: 'Low', sub: 'Safe' },
        fogrisk: { value: 'None', sub: 'Clear' },
        rainprob: { value: '25%', sub: 'Sat PM' },
        rainfree: { value: 'Yes', sub: 'Window' },
        outdoorcomfort: { value: '78°F', sub: 'Excellent' },
        windgustrisk: { value: 'Low', sub: 'Safe' },
        eventconfidence: { value: 'High', sub: 'Good' },
    };
    let html = '';
    active.forEach(p => {
        const info = valueMap[p.id] || { value: '—', sub: '' };
        html += `
            <div class="stat-card">
                <div class="stat-icon"><i class="fas ${p.icon}"></i></div>
                <div class="stat-value">${info.value}</div>
                <div class="stat-label">${p.label}</div>
                <div class="stat-sub">${info.sub}</div>
            </div>
        `;
    });
    statsGrid.innerHTML = html;
}

// ── RENDER OVERLAY ──
function renderOverlayOptions() {
    let html = '';
    personaKeys.forEach(key => {
        const info = personaDisplay[key];
        const isSelected = (tempSelected === key);
        html += `
            <div class="p-option ${isSelected ? 'selected' : ''}" data-key="${key}">
                <i class="fas ${info.icon}"></i>
                <div class="p-name">${info.label}</div>
                <div class="p-desc">${info.desc}</div>
            </div>
        `;
    });
    personaGrid.innerHTML = html;
    personaGrid.querySelectorAll('.p-option').forEach(el => {
        el.addEventListener('click', function() {
            personaGrid.querySelectorAll('.p-option').forEach(o => o.classList.remove('selected'));
            this.classList.add('selected');
            tempSelected = this.dataset.key;
            selectedLabel.textContent = `Selected: ${personaDisplay[tempSelected].label}`;
        });
    });
    if (tempSelected) {
        selectedLabel.textContent = `Selected: ${personaDisplay[tempSelected].label}`;
    } else {
        selectedLabel.textContent = 'No persona selected';
    }
}

// ── RENDER HOME PERSONA ──
function renderHomePersona(key) {
    const data = personaData[key];
    if (!data) {
        personaContent.innerHTML = `
            <div style="text-align:center;padding:30px 10px;color:rgba(255,255,255,0.3);">
                <i class="fas fa-user-circle" style="font-size:40px;color:rgba(255,255,255,0.1);display:block;margin-bottom:12px;"></i>
                <p>No persona selected. Please choose one in settings.</p>
            </div>
        `;
        return;
    }
    let attrHtml = '';
    data.attributes.forEach(item => {
        const isFull = item.label.includes('Guide') || item.label.includes('Risk') || item.label.includes('Alert') ||
            item.label.includes('Status') || item.label.includes('Outlook') || item.label.includes('Warning') ||
            item.label.includes('Score');
        const cls = isFull ? 'p-item p-full' : 'p-item';
        attrHtml += `
            <div class="${cls}">
                <div class="p-label">${item.label}</div>
                <div class="p-value">${item.value} <span class="p-unit">${item.unit}</span></div>
                <div class="p-sub">${item.sub}</div>
            </div>
        `;
    });
    let commonHtml = '';
    commonAttributes.forEach(item => {
        commonHtml += `
            <div class="c-item">
                <div class="c-value">${item.value}</div>
                <div class="c-label">${item.label}</div>
                <div class="c-sub">${item.sub}</div>
            </div>
        `;
    });
    const html = `
        <div class="p-header">
            <i class="fas ${data.icon}"></i>
            <h4>${data.title}</h4>
            <span class="p-badge">${data.badge}</span>
        </div>
        <div class="p-grid">${attrHtml}</div>
        <div class="p-suggestion">
            <i class="fas fa-lightbulb"></i>
            <span>${data.suggestion}</span>
        </div>
        <div class="common-section">
            <div class="common-label"><i class="fas fa-globe" style="margin-right:6px;"></i> Common Weather Data</div>
            <div class="common-grid">${commonHtml}</div>
        </div>
    `;
    personaContent.innerHTML = html;
}

// ── SAVE PERSONA ──
function savePersona(key) {
    if (!key || !personaDisplay[key]) return;
    selectedPersona = key;
    localStorage.setItem('weatherAwarePersona', key);
    tempSelected = key;
    renderHomePersona(key);
    overlay.classList.remove('active');
}

// ── OPEN OVERLAY ──
function openOverlay(isOnboarding = false) {
    if (isOnboarding) {
        overlayTitle.textContent = '👋 Welcome! Choose Your Persona';
        overlaySub.textContent = 'Select a category to personalize your weather insights';
        closeBtn.style.display = 'none';
    } else {
        overlayTitle.textContent = '⚙️ Settings — Change Persona';
        overlaySub.textContent = 'Select a new category for your personalized weather';
        closeBtn.style.display = 'block';
    }
    tempSelected = selectedPersona;
    renderOverlayOptions();
    overlay.classList.add('active');
}

function closeOverlayFn() {
    overlay.classList.remove('active');
}

// ── TAB SWITCHING ──
function switchTab(tab) {
    if (!tab) return;
    currentTab = tab;
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
        item.classList.toggle('active', item.dataset.tab === tab);
    });
    document.querySelectorAll('.tab-pane').forEach(pane => {
        pane.classList.toggle('active', pane.id === 'tab' + tab.charAt(0).toUpperCase() + tab.slice(1));
    });
    document.getElementById('tabContent').scrollTop = 0;
}

// ── WEATHER BACKGROUND ──
const bgElement = document.getElementById('weatherBg');
const conditionText = document.getElementById('conditionText');

function setWeatherBackground(condition) {
    bgElement.className = 'weather-bg';
    const cond = condition.toLowerCase();
    document.getElementById('particlesLayer').innerHTML = '';
    const flash = document.getElementById('flashLayer');
    const stars = document.getElementById('starsLayer');
    const fog = document.getElementById('fogLayer');
    flash.style.display = 'none';
    stars.style.display = 'none';
    fog.style.display = 'none';
    let bgClass = 'clear';
    if (cond.includes('clear') || cond.includes('sunny') || cond.includes('sun')) {
        bgClass = 'clear';
    } else if (cond.includes('cloud') || cond.includes('overcast') || cond.includes('partly')) {
        bgClass = 'cloudy';
    } else if (cond.includes('rain') || cond.includes('drizzle') || cond.includes('shower')) {
        bgClass = 'rainy';
        const container = document.getElementById('particlesLayer');
        for (let i = 0; i < 40; i++) {
            const p = document.createElement('div');
            p.className = 'particle';
            p.style.width = '1.5px';
            p.style.height = (6 + Math.random() * 14) + 'px';
            p.style.left = Math.random() * 100 + '%';
            p.style.animationDuration = (0.4 + Math.random() * 0.7) + 's';
            p.style.animationDelay = (Math.random() * 2) + 's';
            container.appendChild(p);
        }
    } else if (cond.includes('thunder') || cond.includes('storm') || cond.includes('lightning')) {
        bgClass = 'thunder';
        flash.style.display = 'block';
    } else if (cond.includes('night') || cond.includes('evening') || cond.includes('moon')) {
        bgClass = 'night';
        stars.style.display = 'block';
    } else if (cond.includes('fog') || cond.includes('mist') || cond.includes('haze')) {
        bgClass = 'fog';
        fog.style.display = 'block';
    }
    bgElement.classList.add(bgClass);
}

// ── AI CHAT ──
function addMessage(text, sender = 'ai') {
    const time = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const msgDiv = document.createElement('div');
    msgDiv.className = `msg ${sender}`;
    msgDiv.innerHTML = `${text} <span class="msg-time">${time}</span>`;
    chatMessages.appendChild(msgDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

function handleSend() {
    const text = chatInput.value.trim();
    if (!text) return;
    addMessage(text, 'user');
    chatInput.value = '';
    sendBtn.disabled = true;
    setTimeout(() => {
        const responses = [
            "🌤️ Based on current conditions, it's a great day for outdoor activities.",
            "☔ There's a 25% chance of rain tonight. Keep an umbrella handy.",
            "🏃 The best time for a run today is between 6-8 AM.",
            "🧴 UV index is 6 today — don't forget sunscreen.",
            "🚗 Traffic is moderate right now. Allow extra 10-15 minutes.",
            "🌱 Soil moisture is at 42% — consider watering your plants.",
            "🏄 The sea is calm with small waves. Great for swimming.",
            "🧳 If you're traveling to London, pack a raincoat.",
            "🎉 Saturday looks good for events with a 25% rain chance.",
            "👨‍👩‍👧‍👦 School commute is clear today. UV is high, apply sunscreen.",
        ];
        const reply = responses[Math.floor(Math.random() * responses.length)];
        addMessage(reply, 'ai');
        sendBtn.disabled = false;
    }, 800 + Math.random() * 600);
}

// ── NOTIFICATION ──
function toggleNotif() {
    notifPopup.classList.toggle('active');
}

function closeNotif() {
    notifPopup.classList.remove('active');
}

// ── INIT ──
function init() {
    // Persona
    if (!selectedPersona || !personaDisplay[selectedPersona]) {
        selectedPersona = 'general';
        localStorage.setItem('weatherAwarePersona', 'general');
    }
    renderHomePersona(selectedPersona);

    // Background
    const initialCondition = 'Mainly Clear';
    setWeatherBackground(initialCondition);
    conditionText.textContent = initialCondition;

    // Stats
    renderStats();

    // ── EVENTS ──
    settingsIcon.addEventListener('click', function(e) {
        e.stopPropagation();
        openOverlay(false);
    });
    changeLink.addEventListener('click', function(e) {
        e.preventDefault();
        openOverlay(false);
    });
    saveBtn.addEventListener('click', function() {
        if (tempSelected && personaDisplay[tempSelected]) {
            savePersona(tempSelected);
        } else {
            selectedLabel.textContent = '⚠️ Please select a persona first';
        }
    });
    closeBtn.addEventListener('click', closeOverlayFn);
    overlay.addEventListener('click', function(e) {
        if (e.target === this && closeBtn.style.display !== 'none') {
            closeOverlayFn();
        }
    });

    // Plus icon → Parameter panel
    plusIcon.addEventListener('click', openParamPanel);
    paramClose.addEventListener('click', closeParamPanel);
    paramReset.addEventListener('click', function() {
        resetParams();
        if (paramCategoryView.style.display !== 'none') {
            renderCategories();
        }
    });
    paramSave.addEventListener('click', saveParams);
    paramSearch.addEventListener('input', function() {
        if (paramParameterView.style.display !== 'none') {
            renderParams(this.value, currentCategory);
        }
    });
    paramBack.addEventListener('click', function() {
        showCategories();
        paramSearch.value = '';
    });

    // Bell icon → Notification
    bellIcon.addEventListener('click', toggleNotif);
    notifClose.addEventListener('click', closeNotif);
    document.addEventListener('click', function(e) {
        if (!notifPopup.contains(e.target) && e.target !== bellIcon && !bellIcon.contains(e.target)) {
            closeNotif();
        }
    });

    // Tab switching
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
        item.addEventListener('click', function() {
            const tab = this.dataset.tab;
            switchTab(tab);
        });
    });

    // Chat
    sendBtn.addEventListener('click', handleSend);
    chatInput.addEventListener('keydown', function(e) {
        if (e.key === 'Enter') handleSend();
    });

    // ── DEMO: condition cycle ──
    const conditions = ['Mainly Clear', 'Cloudy', 'Rainy', 'Thunderstorm', 'Night', 'Fog'];
    let condIndex = 0;
    document.querySelector('.weather-main').addEventListener('dblclick', function() {
        condIndex = (condIndex + 1) % conditions.length;
        const newCond = conditions[condIndex];
        conditionText.textContent = newCond;
        setWeatherBackground(newCond);
        const iconMap = {
            'Mainly Clear': 'fa-cloud-sun',
            'Cloudy': 'fa-cloud',
            'Rainy': 'fa-cloud-rain',
            'Thunderstorm': 'fa-bolt',
            'Night': 'fa-moon',
            'Fog': 'fa-smog'
        };
        document.querySelector('.weather-icon i').className = 'fas ' + (iconMap[newCond] || 'fa-cloud-sun');
    });

    console.log('🌤️ WeatherAware — AdvisorAI ready.');
    console.log('💡 Double-tap weather area to cycle backgrounds.');
    console.log('🤖 Chat with AdvisorAI for weather tips!');
    console.log('🗺️ Maps tab shows "Coming Soon..." placeholder.');
    console.log('🔔 Notification center: tap bell icon.');
    console.log('➕ Parameter panel: categories → parameters.');
}

document.addEventListener('DOMContentLoaded', init);
