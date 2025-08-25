class CounterApp {
    constructor() {
        this.apiUrl = '/api';
        this.counterValue = document.getElementById('counterValue');
        this.incrementBtn = document.getElementById('incrementBtn');
        this.status = document.getElementById('status');

        this.init();
    }

    async init() {
        await this.loadCounter();
        this.incrementBtn.addEventListener('click', () => this.incrementCounter());
    }

    async loadCounter() {
        try {
            this.showStatus('Yükleniyor...', 'info');
            const response = await fetch(`${this.apiUrl}/counter`);

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            this.counterValue.textContent = data.count;
            this.showStatus('', '');
        } catch (error) {
            console.error('Error loading counter:', error);
            this.showStatus('Bağlantı hatası!', 'error');
        }
    }

    async incrementCounter() {
        try {
            this.incrementBtn.disabled = true;
            this.showStatus('Artırılıyor...', 'info');

            const response = await fetch(`${this.apiUrl}/counter/increment`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            this.counterValue.textContent = data.count;
            this.showStatus('Başarılı!', 'success');

            setTimeout(() => this.showStatus('', ''), 2000);
        } catch (error) {
            console.error('Error incrementing counter:', error);
            this.showStatus('Hata oluştu!', 'error');
        } finally {
            this.incrementBtn.disabled = false;
        }
    }

    showStatus(message, type) {
        this.status.textContent = message;
        this.status.className = `status ${type}`;
    }
}

// App'i başlat
document.addEventListener('DOMContentLoaded', () => {
    new CounterApp();
});
