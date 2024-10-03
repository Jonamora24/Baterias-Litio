% Solicitar las nuevas variables que afectan SOC, SOH y RUL
capacity_nominal = input('Ingrese la capacidad nominal de la batería en Ah: ');
voltage = input('Ingrese el voltaje actual de la batería en V: ');
current = input('Ingrese la corriente actual de la batería en A: ');
resistance_internal = input('Ingrese la resistencia interna actual de la batería en Ohm: ');
temperature = input('Ingrese la temperatura actual de la batería en grados Celsius: ');
cycle_count = input('Ingrese el número de ciclos de carga/descarga de la batería: ');

% Parámetros del filtro UKF
SigmaW = 0.01;  % Ruido del proceso (ajustado para LiFePO4)
SigmaV = 0.01;  % Ruido de la medición (ajustado para LiFePO4)
SigmaZ0 = 0.01; % Variabilidad inicial del SOC (ajustado para LiFePO4)

% Estado inicial
SOC_init = 0.8; % Estado inicial de carga (80%)
SOH_init = 1;   % Estado inicial de salud (100%)
RUL_init = 3000; % Vida útil restante inicial (100 ciclos)

% Función del filtro UKF
[est_SOC, est_SOH, est_RUL] = UKF_battery(voltage, current, capacity_nominal, resistance_internal, temperature, cycle_count, SOC_init, SOH_init, RUL_init, SigmaW, SigmaV, SigmaZ0);

% Mostrar resultados
fprintf('Estimación del SOC: %.2f%%\n', est_SOC * 100);
fprintf('Estimación del SOH: %.2f%%\n', est_SOH * 100);
fprintf('Estimación del RUL: %.2f ciclos\n', est_RUL);

% --- Función del UKF ---
function [SOC_est, SOH_est, RUL_est] = UKF_battery(voltage, current, capacity_nominal, resistance_internal, temperature, cycle_count, SOC_init, SOH_init, RUL_init, SigmaW, SigmaV, SigmaZ0)
    % Inicializar el estado
    SOC_est = SOC_init;
    SOH_est = SOH_init;
    RUL_est = RUL_init;
    
    % Aquí va la lógica del UKF para actualizar el SOC, SOH y RUL
    % Modelo de batería (ajustado para LiFePO4)
    dt = 1; % intervalo de tiempo en horas
    
    % Ajustes para evitar caída rápida del SOC y RUL
    current = min(current, 0.2 * capacity_nominal); % Limitar corriente a un máximo del 20% de la capacidad nominal

for t = 1:100  % Simulación de 100 pasos
    % Modelo básico de SOC
    % Se reduce menos agresivamente el SOC
    SOC_est = SOC_est - (current / capacity_nominal) * dt * 0.01; % Reduce the decrease rate
    SOC_est = max(0, min(SOC_est, 1)); % Limitar el SOC entre 0 y 1
    
    % Actualización del SOH basado en resistencia interna y ciclos
    % Degradación reducida para evitar caída rápida
    SOH_est = SOH_est - 0.001 * resistance_internal; % Increase the degradation rate
    SOH_est = max(0, SOH_est); % Asegurar que el SOH no sea negativo
    
    % Estimación del RUL basado en SOH y ciclos
    % Ajustar el impacto de los ciclos y el SOH
    RUL_est = max(0, RUL_init - 0.1 * cycle_count * (1 - SOH_est) - 0.05 * cycle_count * (1 + 0.01 * (temperature - 25))); % Increase the impact of cycles and SOH, and adjust for temperature
end
end
