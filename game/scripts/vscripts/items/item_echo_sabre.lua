function DoubleAttack(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local level_map = {
		[1] = "modifier_item_echo_sabre_arena",
		[2] = "modifier_item_echo_sabre_2",
		[3] = "modifier_item_fallhammer",
	}
	for i,v in ipairs(level_map) do
		if i > keys.level then
			if caster:HasModifier(v) then
				return
			end
		end
	end
	if PreformAbilityPrecastActions(caster, ability) then
		Timers:CreateTimer(ability:GetAbilitySpecial("attack_delay"), function()
			local can = true
			if not IsRangedUnit(caster) and caster.AttackFuncs and caster.AttackFuncs.bNoDoubleAttackMelee ~= nil then
				can = not caster.AttackFuncs.bNoDoubleAttackMelee
			end
			if can then
				if not IsRangedUnit(caster) then
					PerformGlobalAttack(caster, target, true, true, true, true, true, {bNoDoubleAttackMelee = true})
				end
				ability:ApplyDataDrivenModifier(caster, target, keys.modifier, nil)
				if keys.Damage then
					ApplyDamage({
						victim = target,
						attacker = caster,
						damage = keys.Damage,
						damage_type = ability:GetAbilityDamageType(),
						ability = ability
					})
				end
				if keys.TargetSound then
					target:EmitSound(keys.TargetSound)
				end
			end
		end)
	end
end