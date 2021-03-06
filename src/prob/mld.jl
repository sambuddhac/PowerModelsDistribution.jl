"Solve load shedding problem with storage"
function solve_mc_mld(data::Union{Dict{String,<:Any},String}, model_type::Type, solver; kwargs...)
    return solve_mc_model(data, model_type, solver, build_mc_mld; kwargs...)
end


"Solve multinetwork load shedding problem with storage"
function solve_mn_mc_mld_simple(data::Union{Dict{String,<:Any},String}, model_type::Type, solver; kwargs...)
    return solve_mc_model(data, model_type, solver, build_mn_mc_mld_simple; multinetwork=true, kwargs...)
end


"Solve unit commitment load shedding problem (!relaxed)"
function solve_mc_mld_uc(data::Union{Dict{String,<:Any},String}, model_type::Type, solver; kwargs...)
    return solve_mc_model(data, model_type, solver, build_mc_mld_uc; kwargs...)
end


"Load shedding problem including storage (snap-shot)"
function build_mc_mld(pm::_PM.AbstractPowerModel)
    variable_mc_bus_voltage_indicator(pm; relax=true)
    variable_mc_bus_voltage_on_off(pm)

    variable_mc_branch_power(pm)
    variable_mc_switch_power(pm)
    variable_mc_transformer_power(pm)

    variable_mc_gen_indicator(pm; relax=true)
    variable_mc_generator_power_on_off(pm)

    variable_mc_storage_indicator(pm, relax=true)
    variable_mc_storage_power_mi_on_off(pm, relax=true)

    variable_mc_load_indicator(pm; relax=true)
    variable_mc_shunt_indicator(pm; relax=true)

    constraint_mc_model_voltage(pm)

    for i in ids(pm, :ref_buses)
        constraint_mc_theta_ref(pm, i)
    end

    constraint_mc_bus_voltage_on_off(pm)

    for i in ids(pm, :gen)
        constraint_mc_gen_power_on_off(pm, i)
    end

    for i in ids(pm, :bus)
        constraint_mc_power_balance_shed(pm, i)
    end

    for i in ids(pm, :storage)
        _PM.constraint_storage_state(pm, i)
        _PM.constraint_storage_complementarity_mi(pm, i)
        constraint_mc_storage_on_off(pm, i)
        constraint_mc_storage_losses(pm, i)
        constraint_mc_storage_thermal_limit(pm, i)
    end

    for i in ids(pm, :branch)
        constraint_mc_ohms_yt_from(pm, i)
        constraint_mc_ohms_yt_to(pm, i)

        constraint_mc_voltage_angle_difference(pm, i)

        constraint_mc_thermal_limit_from(pm, i)
        constraint_mc_thermal_limit_to(pm, i)
    end

    for i in ids(pm, :switch)
        constraint_mc_switch_state(pm, i)
        constraint_mc_switch_thermal_limit(pm, i)
    end

    for i in ids(pm, :transformer)
        constraint_mc_transformer_power(pm, i)
    end

    objective_mc_min_load_setpoint_delta(pm)
end


""
function build_mc_mld(pm::_PM.AbstractIVRModel)
    Memento.error(_LOGGER, "IVRPowerModel is not yet supported in the MLD problem space")
    # TODO
end


"Multinetwork load shedding problem including storage"
function build_mn_mc_mld_simple(pm::_PM.AbstractPowerModel)
    for (n, network) in _PM.nws(pm)
        variable_mc_branch_power(pm; nw=n)
        variable_mc_switch_power(pm; nw=n)
        variable_mc_transformer_power(pm; nw=n)
        variable_mc_generator_power(pm; nw=n)
        variable_mc_bus_voltage(pm; nw=n)

        variable_mc_load_indicator(pm; nw=n, relax=true)
        variable_mc_shunt_indicator(pm; nw=n, relax=true)
        variable_mc_storage_power_mi(pm; nw=n, relax=true)

        constraint_mc_model_voltage(pm; nw=n)

        for i in ids(pm, n, :ref_buses)
            constraint_mc_theta_ref(pm, i; nw=n)
        end

        for i in ids(pm, n, :gen)
            constraint_mc_generator_power(pm, i; nw=n)
        end

        for i in ids(pm, n, :bus)
            constraint_mc_power_balance_shed(pm, i; nw=n)
        end

        for i in ids(pm, n, :storage)
            constraint_mc_storage_losses(pm, i; nw=n)
            constraint_mc_storage_thermal_limit(pm, i; nw=n)
            _PM.constraint_storage_complementarity_mi(pm, i; nw=n)
        end

        for i in ids(pm, n, :branch)
            constraint_mc_ohms_yt_from(pm, i; nw=n)
            constraint_mc_ohms_yt_to(pm, i; nw=n)
            constraint_mc_voltage_angle_difference(pm, i; nw=n)
            constraint_mc_thermal_limit_from(pm, i; nw=n)
            constraint_mc_thermal_limit_to(pm, i; nw=n)
        end

        for i in ids(pm, n, :switch)
            constraint_mc_switch_state(pm, i; nw=n)
            constraint_mc_switch_thermal_limit(pm, i; nw=n)
        end

        for i in ids(pm, n, :transformer)
            constraint_mc_transformer_power(pm, i; nw=n)
        end
    end

    network_ids = sort(collect(_PM.nw_ids(pm)))

    n_1 = network_ids[1]

    for i in _PM.ids(pm, :storage; nw=n_1)
        _PM.constraint_storage_state(pm, i; nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in _PM.ids(pm, :storage; nw=n_2)
            _PM.constraint_storage_state(pm, i, n_1, n_2)
        end

        n_1 = n_2
    end

    objective_mc_min_load_setpoint_delta_simple(pm)
end


"Load shedding problem for Branch Flow model"
function build_mc_mld(pm::AbstractUBFModels)
    variable_mc_bus_voltage_indicator(pm; relax=true)
    variable_mc_bus_voltage_on_off(pm)

    variable_mc_branch_current(pm)
    variable_mc_branch_power(pm)
    variable_mc_switch_power(pm)
    variable_mc_transformer_power(pm)

    variable_mc_gen_indicator(pm; relax=true)
    variable_mc_generator_power_on_off(pm)

    variable_mc_storage_indicator(pm, relax=true)
    variable_mc_storage_power_mi_on_off(pm, relax=true)

    variable_mc_load_indicator(pm; relax=true)
    variable_mc_shunt_indicator(pm; relax=true)

    constraint_mc_model_current(pm)

    for i in ids(pm, :ref_buses)
        constraint_mc_theta_ref(pm, i)
    end

    constraint_mc_bus_voltage_on_off(pm)

    for i in ids(pm, :gen)
        constraint_mc_gen_power_on_off(pm, i)
    end

    for i in ids(pm, :bus)
        constraint_mc_power_balance_shed(pm, i)
    end

    for i in ids(pm, :storage)
        _PM.constraint_storage_state(pm, i)
        _PM.constraint_storage_complementarity_mi(pm, i)
        constraint_mc_storage_on_off(pm, i)
        constraint_mc_storage_losses(pm, i)
        constraint_mc_storage_thermal_limit(pm, i)
    end

    for i in ids(pm, :branch)
        constraint_mc_power_losses(pm, i)
        constraint_mc_model_voltage_magnitude_difference(pm, i)

        constraint_mc_voltage_angle_difference(pm, i)

        constraint_mc_thermal_limit_from(pm, i)
        constraint_mc_thermal_limit_to(pm, i)
    end

    for i in ids(pm, :switch)
        constraint_mc_switch_state(pm, i)
        constraint_mc_switch_thermal_limit(pm, i)
    end

    for i in ids(pm, :transformer)
        constraint_mc_transformer_power(pm, i)
    end

    objective_mc_min_load_setpoint_delta(pm)
end


"Multinetwork load shedding problem for Branch Flow model"
function build_mn_mc_mld_simple(pm::AbstractUBFModels)
    for (n, network) in _PM.nws(pm)
        variable_mc_branch_current(pm; nw=n)
        variable_mc_branch_power(pm; nw=n)
        variable_mc_switch_power(pm; nw=n)
        variable_mc_transformer_power(pm; nw=n)
        variable_mc_generator_power(pm; nw=n)
        variable_mc_bus_voltage(pm; nw=n)

        variable_mc_load_indicator(pm; nw=n, relax=true)
        variable_mc_shunt_indicator(pm; nw=n, relax=true)
        variable_mc_storage_power_mi(pm; nw=n, relax=true)

        constraint_mc_model_current(pm; nw=n)

        for i in ids(pm, n, :ref_buses)
            constraint_mc_theta_ref(pm, i; nw=n)
        end

        for i in ids(pm, n, :gen)
            constraint_mc_generator_power(pm, i; nw=n)
        end

        for i in ids(pm, n, :bus)
            constraint_mc_power_balance_shed(pm, i; nw=n)
        end

        for i in ids(pm, n, :storage)
            constraint_mc_storage_losses(pm, i; nw=n)
            constraint_mc_storage_thermal_limit(pm, i; nw=n)
            _PM.constraint_storage_complementarity_mi(pm, i; nw=n)
        end

        for i in ids(pm, n, :branch)
            constraint_mc_power_losses(pm, i; nw=n)
            constraint_mc_model_voltage_magnitude_difference(pm, i; nw=n)
            constraint_mc_voltage_angle_difference(pm, i; nw=n)
            constraint_mc_thermal_limit_from(pm, i; nw=n)
            constraint_mc_thermal_limit_to(pm, i; nw=n)
        end

        for i in ids(pm, n, :switch)
            constraint_mc_switch_state(pm, i; nw=n)
            constraint_mc_switch_thermal_limit(pm, i)
        end

        for i in ids(pm, n, :transformer)
            constraint_mc_transformer_power(pm, i; nw=n)
        end
    end

    network_ids = sort(collect(_PM.nw_ids(pm)))

    n_1 = network_ids[1]

    for i in _PM.ids(pm, :storage; nw=n_1)
        _PM.constraint_storage_state(pm, i; nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in _PM.ids(pm, :storage; nw=n_2)
            _PM.constraint_storage_state(pm, i, n_1, n_2)
        end

        n_1 = n_2
    end

    objective_mc_min_load_setpoint_delta_simple(pm)
end


"Load shedding problem for Branch Flow model"
function build_mc_mld_bf(pm::_PM.AbstractPowerModel)
    build_mc_mld(pm)

    variable_mc_bus_voltage_indicator(pm; relax=true)
    variable_mc_bus_voltage_on_off(pm)

    variable_mc_branch_current(pm)
    variable_mc_branch_power(pm)
    variable_mc_switch_power(pm)
    variable_mc_transformer_power(pm)

    variable_mc_gen_indicator(pm; relax=true)
    variable_mc_generator_power_on_off(pm)

    variable_mc_load_indicator(pm; relax=true)
    variable_mc_shunt_indicator(pm; relax=true)

    constraint_mc_model_current(pm)

    for i in ids(pm, :ref_buses)
        constraint_mc_theta_ref(pm, i)
    end

    constraint_mc_bus_voltage_on_off(pm)

    for i in ids(pm, :gen)
        constraint_mc_gen_power_on_off(pm, i)
    end

    for i in ids(pm, :bus)
        constraint_mc_power_balance_shed(pm, i)
    end

    for i in ids(pm, :branch)
        constraint_mc_power_losses(pm, i)
        constraint_mc_model_voltage_magnitude_difference(pm, i)

        constraint_mc_voltage_angle_difference(pm, i)

        constraint_mc_thermal_limit_from(pm, i)
        constraint_mc_thermal_limit_to(pm, i)
    end

    for i in ids(pm, :switch)
        constraint_mc_switch_state(pm, i)
        constraint_mc_switch_thermal_limit(pm, i)
    end

    for i in ids(pm, :transformer)
        constraint_mc_transformer_power(pm, i)
    end

    objective_mc_min_load_setpoint_delta(pm)
end


"Standard unit commitment (!relaxed) load shedding problem"
function build_mc_mld_uc(pm::_PM.AbstractPowerModel)
    variable_mc_bus_voltage_indicator(pm; relax=false)
    variable_mc_bus_voltage_on_off(pm)

    variable_mc_branch_power(pm)
    variable_mc_switch_power(pm)
    variable_mc_transformer_power(pm)

    variable_mc_gen_indicator(pm; relax=false)
    variable_mc_generator_power_on_off(pm)

    variable_mc_storage_power(pm)
    variable_mc_storage_indicator(pm; relax=false)
    variable_mc_storage_power_on_off(pm)

    variable_mc_load_indicator(pm; relax=false)
    variable_mc_shunt_indicator(pm; relax=false)

    constraint_mc_model_voltage(pm)

    for i in ids(pm, :ref_buses)
        constraint_mc_theta_ref(pm, i)
    end

    constraint_mc_bus_voltage_on_off(pm)

    for i in ids(pm, :gen)
        constraint_mc_gen_power_on_off(pm, i)
    end

    for i in ids(pm, :bus)
        constraint_mc_power_balance_shed(pm, i)
    end

    for i in ids(pm, :storage)
        _PM.constraint_storage_state(pm, i)
        _PM.constraint_storage_complementarity_nl(pm, i)
        constraint_mc_storage_losses(pm, i)
        constraint_mc_storage_thermal_limit(pm, i)
    end

    for i in ids(pm, :branch)
        constraint_mc_ohms_yt_from(pm, i)
        constraint_mc_ohms_yt_to(pm, i)

        constraint_mc_voltage_angle_difference(pm, i)

        constraint_mc_thermal_limit_from(pm, i)
        constraint_mc_thermal_limit_to(pm, i)
    end

    for i in ids(pm, :switch)
        constraint_mc_switch_state(pm, i)
        constraint_mc_switch_thermal_limit(pm, i)
    end

    for i in ids(pm, :transformer)
        constraint_mc_transformer_power(pm, i)
    end

    objective_mc_min_load_setpoint_delta(pm)
end

# Depreciated run_ functions (remove after ~4-6 months)

"depreciation warning for run_mc_mld"
function run_mc_mld(data::Union{Dict{String,<:Any},String}, model_type::Type, solver; kwargs...)
    @warn "run_mc_mld is being depreciated in favor of solve_mc_mld, please update your code accordingly"
    return solve_mc_mld(data, model_type, solver; kwargs...)
end


"depreciation warning for run_mn_mc_mld_simple"
function run_mn_mc_mld_simple(data::Union{Dict{String,<:Any},String}, model_type::Type, solver; kwargs...)
    @warn "run_mn_mc_mld_simple is being depreciated in favor of solve_mn_mc_mld_simple, please update your code accordingly"
    return solve_mn_mc_mld_simple(data, model_type, solver; kwargs...)
end


"depreciation warning for run_mc_mld_bf"
function run_mc_mld_bf(data::Union{Dict{String,<:Any},String}, model_type::Type, solver; kwargs...)
    @warn "run_mc_mld_bf is being depreciated in favor of solve_mc_mld, please update your code accordingly"
    return solve_mc_mld(data, model_type, solver; kwargs...)
end


"depreciation warning for run_mc_mld_uc"
function run_mc_mld_uc(data::Union{Dict{String,<:Any},String}, model_type::Type, solver; kwargs...)
    @warn "run_mc_mld_uc is being depreciated in favor of solve_mc_mld_uc, please update your code accordingly"
    return solve_mc_mld_uc(data, model_type, solver; kwargs...)
end
