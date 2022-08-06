#include <sourcemod>

enum struct mempatch_t
{
	Address iAddrPatch;
	int iByteOrigin;
	char patch[4];

	bool Setup(GameData conf, const char[] address, const char[] key)
	{
		Address base;
		if ((base = conf.GetAddress(address)) == Address_Null)
		{
			SetFailState("Failed to get address -> \'%s\'.", address);
			return false;
		}

		if (!conf.GetKeyValue(key, this.patch, sizeof(mempatch_t::patch)))
		{
			SetFailState("Failed to get keyvalue -> \'%s\'.", key);
			return false;
		}

		this.iAddrPatch = base;
		this.iByteOrigin = LoadFromAddress(base, NumberType_Int8);
		return true;
	}

	void Apply()
	{
		if(this.iAddrPatch != Address_Null)
		{
			StoreToAddress(this.iAddrPatch, StringToInt(this.patch, 16), NumberType_Int8);
		}
	}

	void Restore()
	{
		if(this.iAddrPatch != Address_Null)
		{
			StoreToAddress(this.iAddrPatch, this.iByteOrigin, NumberType_Int8);
		}
	}
}

mempatch_t g_patch[2];

public void OnPluginStart()
{
	SetupPatch();
}

public void OnPluginEnd()
{
	RestorePatch();
}

void SetupPatch()
{
	GameData gd = new GameData("no-steam-auth-session.games");

	if (gd == null)
	{
		SetFailState("cannot find \'no-steam-auth-session.games.txt\'");
		return;
	}

	bool windows = (gd.GetOffset("OS") == 1);

	if (!g_patch[0].Setup(gd, "jnz_base_1", "jnz1_patch"))
	{
		return;
	}

	if (windows && !g_patch[1].Setup(gd, "jnz_base_2", "jnz2_patch"))
	{
		return;
	}

	ApplyPatch();

	delete gd;
}

void ApplyPatch()
{
	for (int i = 0; i < sizeof(g_patch); i++)
	{
		g_patch[i].Apply();
	}
}

void RestorePatch()
{
	for (int i = 0; i < sizeof(g_patch); i++)
	{
		g_patch[i].Restore();
	}
}